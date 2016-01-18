open Lwt

open V1
open V1_LWT
open Sexplib.Conv
open Astring

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
    let repr = String.Ascii.escape (Cstruct.to_string buf) in
    C.log_s c (Colour.blue "  %s: " str ^ repr)
  and error c e = C.log_s c (Colour.red "+ err: %s" e)
  and warn c str = C.log_s c (Colour.red str)
end

module Client
    (C: CONSOLE)
    (Clock: V1.CLOCK)
    (Time: V1_LWT.TIME)
    (Resolver: Resolver_lwt.S)
    (Conduit: Conduit_mirage.S)
    (S:Cohttp_lwt.Server)
    (SECRETS: KV_RO)
    (ASSETS: KV_RO)
    (DECKS: KV_RO)
= struct

  module L = Log(C)

  let start c _clock _time res con http secrets assets decks =
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

    let read_decks name =
      DECKS.size decks name >>= function
      | `Error (DECKS.Unknown_key _) ->
        fail (Failure ("read_decks_size " ^ name))
      | `Ok size ->
        DECKS.read decks name 0 (Int64.to_int size) >>= function
        | `Error (DECKS.Unknown_key _) ->
          fail (Failure ("read_decks " ^ name))
        | `Ok bufs -> return (Cstruct.copyv bufs)
    in

    let callback conn_id req body =
      let sp = Printf.sprintf in

      let respond_ok bodyt = bodyt
        >>= fun body ->
        S.respond_string ~status:`OK ~body ()
      in

      let respond_notfound req =
        S.respond_not_found ~uri:(Cohttp.Request.uri req) ()
      in

      let path = req |> Cohttp.Request.uri |> Uri.path in
      L.trace c (sp "URL: '%s'" path)
      >>= fun () ->

      let cpts = path
                 |> Re_str.(split_delim (regexp_string "/"))
                 |> List.filter (fun e -> e <> "")
      in
      match cpts with
      | [] -> Site.index () |> respond_ok

      | "ia-os" :: lecture :: [] when (String.is_suffix ~affix:".md" lecture) ->
        Lwt.catch
          (fun () -> read_decks lecture |> respond_ok)
          (fun e -> S.respond_not_found ~uri:(Cohttp.Request.uri req) ())

      | "ia-os" :: lecture :: [] ->
        Lwt.catch
          (fun () -> Site.lecture ~lecture |> respond_ok)
          (function
            | Not_found -> req |> respond_notfound
            | e -> Lwt.fail e
          )

      | "plugin" :: rest ->
        Lwt.catch
          (fun () -> read_assets ("reveal.js-3.2.0" ^ path) |> respond_ok)
          (fun e -> S.respond_not_found ~uri:(Cohttp.Request.uri req) ())

      | _ ->
        Lwt.catch
          (fun () -> read_assets path |> respond_ok)
          (fun e -> S.respond_not_found ~uri:(Cohttp.Request.uri req) ())

    in
    let conn_closed (_, conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      C.log c (Printf.sprintf "conn %s closed" cid)
    in

    let spec = S.make ~callback ~conn_closed () in
    http (`TCP 8080) spec

end
