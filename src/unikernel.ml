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

module Client
    (C: CONSOLE)
    (Clock: V1.CLOCK)
    (Time: V1_LWT.TIME)
    (Resolver: Resolver_lwt.S)
    (Conduit: Conduit_mirage.S)
    (S: Cohttp_lwt.Server)
    (SECRETS: KV_RO)
    (ASSETS: KV_RO) =
struct

  let start c _clock _time res con http secrets assets =
    let read_assets name =
      ASSETS.size assets name >>= function
      | `Error (ASSETS.Unknown_key _) ->
        fail (Failure ("read_assets_size " ^ name))
      | `Ok size ->
        ASSETS.read assets name 0 (Int64.to_int size) >>= function
        | `Error (ASSETS.Unknown_key _) ->
          fail (Failure ("read_assets " ^ name))
        | `Ok bufs -> return (Cstruct.copyv bufs)
    in

    let callback conn_id req body =
      let sp = Printf.sprintf in
      let dynamic read_slides req path =
        Printf.(
          eprintf "DISPATCH: %s\n%!"
            (sprintf "[ %s ]"
               (String.concat "; " (List.map (fun c -> sprintf "'%s'" c) path))
            ));

        let respond_ok body =
          lwt body = body in
          S.respond_string ~status:`OK ~body ()
        in
        match path with
        | [] | [""] ->
          Slides.index read_slides ~req ~path |> respond_ok
        | deck :: [] ->
          Slides.deck read_slides ~deck |> respond_ok
        | deck :: asset :: [] ->
          Slides.asset read_slides ~deck ~asset |> respond_ok
        | x -> S.respond_not_found ~uri:(Cohttp.Request.uri req) ()
      in

      let dispatch ~c_log ~read_assets ~read_slides ~conn_id ~req =
        let path = req |> Cohttp.Request.uri |> Uri.path in
        let cpts = path
                   |> Re_str.(split_delim (regexp_string "/"))
                   |> List.filter (fun e -> e <> "")
        in
        c_log (sp "URL: '%s'" path)
        >>= fun () ->
        Lwt.catch
          (fun () ->
             read_assets path >>= fun body ->
             S.respond_string ~status:`OK ~body ()
          ) (function
              | Failure m ->
                Printf.printf "CATCH: '%s'\n%!" m;
                dynamic read_slides req cpts
              | e -> Lwt.fail e)
      in

      dispatch ~c_log ~read_assets ~read_slides ~conn_id ~req
    in
    let conn_closed (_, conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      C.log c (Printf.sprintf "conn %s closed" cid)
    in

    let spec = S.make ~callback ~conn_closed () in
    http (`TCP 80) spec

end
