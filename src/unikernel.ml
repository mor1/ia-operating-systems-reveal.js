open Lwt.Infix
open Mirage_types_lwt

let highlight_js = "highlight.js-9.9.0"
let reveal_js = "reveal.js-3.3.0"

let http_src = Logs.Src.create "http" ~doc:"HTTP server"
module Http_log = (val Logs.src_log http_src : Logs.LOG)

let endswith suffix s = Astring.String.is_suffix ~affix:suffix s

module Http
    (S: Cohttp_lwt.Server)
    (SECRETS: KV_RO)
    (ASSETS: KV_RO)
    (DECKS: KV_RO)
= struct

  let fail_with fmt = Fmt.kstrf Lwt.fail_with fmt

  let safe_read ~pp_error ~size ~read device name =
    size device name >>= function
    | Error e -> fail_with "%a" pp_error e
    | Ok size ->
      read device name 0L size >>= function
      | Error e -> fail_with "%a" pp_error e
      | Ok bufs -> Lwt.return (Cstruct.copyv bufs)

  let respond_ok path bodyt = bodyt >>= fun body ->
    let mime_type = Magic_mime.lookup path in
    let headers = Cohttp.Header.init () in
    let headers = Cohttp.Header.add headers "content-type" mime_type in
    S.respond_string ~status:`OK ~body ~headers ()

  let respond_notfound uri = S.respond_not_found ~uri ()

  let rec dispatcher read_asset read_deck uri =
    let path = Uri.path uri in
    Http_log.info (fun f -> f "request '%s'" path);

    let cpts = Astring.String.cuts ~empty:false ~sep:"/" path in
    match cpts with
    | [] | [""] ->
      dispatcher read_asset read_deck (Uri.with_path uri "index.html")
    | ["index.html"] -> Site.index () |> respond_ok path

    | "ia-os" :: lecture :: []
      when ((endswith ".md" lecture) || (endswith ".png" lecture))
      ->
      Lwt.catch
        (fun () -> read_deck lecture |> respond_ok path)
        (fun _ -> respond_notfound uri)

    | "ia-os" :: lecture :: [] ->
      Lwt.catch
        (fun () -> Site.lecture ~lecture |> respond_ok (lecture^".html"))
        (fun _ ->  respond_notfound uri)

    | "plugin" :: _ ->
      Lwt.catch
        (fun () -> read_asset (reveal_js ^ path) |> respond_ok path)
        (fun e -> respond_notfound uri)

    | _ ->
      Lwt.catch
        (fun () -> read_asset path |> respond_ok path)
        (fun _ -> respond_notfound uri)

  let start http _secrets assets decks =
    let read_asset n = safe_read
        ~pp_error:ASSETS.pp_error ~size:ASSETS.size ~read:ASSETS.read assets n
    in

    let read_deck n = safe_read
        ~pp_error:DECKS.pp_error ~size:DECKS.size ~read:DECKS.read decks n
    in

    let callback (_, cid) request _body =
      let uri = Cohttp.Request.uri request in
      let cid = Cohttp.Connection.to_string cid in
      Http_log.info (fun f -> f "[%s] serving %s" cid (Uri.to_string uri));
      dispatcher read_asset read_deck uri
    in

    let conn_closed (_, cid) =
      let cid = Cohttp.Connection.to_string cid in
      Http_log.info (fun f -> f "[%s] closing" cid);
    in

    let port = Key_gen.port () in
    Http_log.info (fun f -> f "listening on %d/TCP" port);
    http (`TCP port) (S.make ~conn_closed ~callback ())

end
