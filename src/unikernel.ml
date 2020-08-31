open Lwt.Infix

let highlight_js = "highlight.js-9.9.0"
let reveal_js = "reveal.js-3.3.0"

module type HTTP = Cohttp_lwt.S.Server

let http_src = Logs.Src.create "http" ~doc:"HTTP server"
module Http_log = (val Logs.src_log http_src : Logs.LOG)

let endswith suffix s = Astring.String.is_suffix ~affix:suffix s

module Http
    (S: HTTP)
    (SECRETS: Mirage_kv.RO)
    (ASSETS: Mirage_kv.RO)
    (DECKS: Mirage_kv.RO)
= struct

  let failf fmt = Fmt.kstrf Lwt.fail_with fmt

  let safe_read ~pp_error ~get device path =
    get device (Mirage_kv.Key.v path) >>= function
    | Error e -> failf "get: %a" pp_error e
    | Ok body -> Lwt.return body

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
        (fun _e -> respond_notfound uri)

    | _ ->
      Lwt.catch
        (fun () -> read_asset path |> respond_ok path)
        (fun _ -> respond_notfound uri)

  let start http _secrets assets decks =
    let read_asset n = safe_read
        ~pp_error:ASSETS.pp_error ~get:ASSETS.get assets n
    in

    let read_deck n = safe_read
        ~pp_error:DECKS.pp_error ~get:DECKS.get decks n
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
