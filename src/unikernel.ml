open Lwt

open V1
open V1_LWT
open Sexplib.Conv

type ('a, 'e, 'c) m = ([< `Ok of 'a | `Error of 'e | `Eof ] as 'c) Lwt.t

let (>>==) (a : ('a, 'e, _) m) (f : 'a -> ('b, 'e, _) m) : ('b, 'e, _) m =
  a >>= function
  | `Ok x -> f x
  | `Error _ | `Eof as e -> return e

module Colour = struct
  open Printf
  let red    fmt = sprintf ("\027[31m"^^fmt^^"\027[m")
  let green  fmt = sprintf ("\027[32m"^^fmt^^"\027[m")
  let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
  let blue   fmt = sprintf ("\027[36m"^^fmt^^"\027[m")
end

module Log (C: CONSOLE) = struct
  let trace c str = C.log_s c (Colour.green "+ %s" str)
  and data c str buf =
    let repr = String.escaped (Cstruct.to_string buf) in
    C.log_s c (Colour.blue "  %s: " str ^ repr)
  and error c e = C.log_s c (Colour.red "+ err: %s" e)
end

module Gh_clock (Clock: V1.CLOCK) (Time: V1_LWT.TIME) : Github_s.Time = struct
  let now () = Clock.time ()
  let sleep n = Time.sleep n
end

let user = "mor1"

module Client
    (C: CONSOLE)
    (Clock: V1.CLOCK)
    (Time: V1_LWT.TIME)
    (Resolver: Resolver_lwt.S)
    (Conduit: Conduit_mirage.S)
    (SECRETS: KV_RO) =
struct

  module I   = Irmin
  module Log = Log(C)
  module GHC = Gh_clock(Clock)(Time)

  let start c _clock _time res con secrets =
    (* Build `Github` module for interactions with API *)
    let module Resolving_client = struct

      module Channel = Channel.Make(Conduit_mirage.Flow)
      module HTTP_IO = Cohttp_mirage_io.Make(Channel)

      module Net_IO = struct

        module IO = HTTP_IO

        type 'a io = 'a Lwt.t
        type ic = Channel.t
        type oc = Channel.t
        type flow = Conduit_mirage.Flow.flow

        type ctx = {
          resolver: Resolver_lwt.t;
          conduit : Conduit_mirage.t;
        }

        let sexp_of_ctx { resolver; _ } = Resolver_lwt.sexp_of_t resolver

        let default_ctx =
          { resolver = res; conduit = con }

        let connect_uri ~ctx uri =
          Resolver_lwt.resolve_uri ~uri ctx.resolver
          >>= fun endp ->
          Conduit_mirage.client endp
          >>= fun client ->
          Conduit_mirage.connect ctx.conduit client
          >>= fun flow ->
          let ch = Channel.create flow in
          return (flow, ch, ch)

        let _close channel = Lwt.catch
                               (fun () -> Channel.close channel)
                               (fun _ -> return_unit)
        let close_in ic = ignore_result (_close ic)
        let close_out ic = ignore_result (_close ic)
        let close ic oc = ignore_result (_close ic >>= fun () -> _close oc)

      end
      let ctx resolver conduit = { Net_IO.resolver; conduit }

      (* Build all the core modules from the [Cohttp_lwt] functors *)
      include Cohttp_lwt.Make_client(HTTP_IO)(Net_IO)

    end in
    let module Github = Github_core.Make(GHC)(Resolving_client) in

    (* Build Context and Inflator modules for Mirage/Irmin *)
    let module Context = struct
      let v () = Lwt.return (Some (res, con))
    end in

    let module Inflator = struct
      module IDBytes = struct
        include Bytes
        let concat = String.concat
        let of_bytes t = t
        let to_bytes t = t
      end
      module XInflator = Decompress.Inflate.Make(IDBytes)
      module XDeflator = Decompress.Deflate.Make(IDBytes)

      (* TODO: this is real pokey *)
      let inflate ?output_size buf =
        C.log c "inflating buffer: ";
        Mstruct.hexdump buf;
        let output = match output_size with
          | None -> Bytes.create (Mstruct.length buf)
          | Some n -> Bytes.create n
        in
        let inflator =
          XInflator.make (`String (0, (Mstruct.to_string buf))) output
        in
        let rec eventually_inflate inflator acc =
          match XInflator.eval inflator with
          | `Ok ->
            let res = Mstruct.of_string (IDBytes.concat "" (List.rev acc)) in
            C.log c (Printf.sprintf "result is length %d: %s"
                       (Mstruct.length res)
                       (Mstruct.to_string res)
                    );
            Some (Mstruct.of_string (IDBytes.concat "" (List.rev (acc))))
          | `Error -> None
          | `Flush ->
            let tmp = Bytes.copy output in
            XInflator.flush inflator;
            eventually_inflate inflator (tmp :: acc)
        in
        eventually_inflate inflator []

      let deflate ?level buf =
        let output = Bytes.create (Cstruct.len buf) in
        let deflator =
          XDeflator.make ~window_bits:((Cstruct.len buf)*8)
            (`String (0, (Cstruct.to_string buf))) output
        in
        let rec eventually_deflate deflator acc =
          match XDeflator.eval deflator with
          | `Ok ->
            Cstruct.of_string (IDBytes.concat "" (List.rev (output::acc)))
          | `Error -> failwith "Error deflating an archive :("
          | `Flush ->
            let tmp = Bytes.copy output in
            XDeflator.flush deflator;
            eventually_deflate deflator (tmp :: acc)
        in
        eventually_deflate deflator []

    end in

    (* Build the Mirage/Irmin modules *)
    let module Store =
      Irmin_mirage.Irmin_git.Memory
        (Context)(Inflator)(I.Contents.String)(I.Ref.String)(I.Hash.SHA1)
    in
    let module Sync = I.Sync(Store) in
    let module View = I.View(Store) in

    (* Stop playing with module bricks and build some actual values... *)

    SECRETS.read secrets "token" 0 4096 >>= function
    | `Error _ | `Ok [] | `Ok (_::_::_) ->
      Log.error c "secrets kv_ro error reading token"
    | `Ok (buf::[]) ->
      Lwt.return (Github.Token.of_string (Cstruct.to_string buf))
      >>= fun token ->
      C.log c "token read!";

      let config = Irmin_mirage.Irmin_git.config () in
      let task =
        let date = Int64.of_float (Clock.time ()) in
        let owner = "MirageOS Irmin Webserver" in
        I.Task.create ~date ~owner
      in

      let path = "git://github.com/mor1/ia-operating-systems.wiki.git" in
      let remote = I.remote_uri path in
      Store.Repo.create config
      >>= fun repo ->
      Store.master task repo

      >>= fun primary ->
      Sync.pull_exn (primary "Sync remote") remote `Update
      >>= fun () ->
      Store.read_exn (primary "Get Home.md") ["Home.md"]
      >>= fun home ->
      C.log c (Printf.sprintf "%s\n%!" home);
      return_unit
end
