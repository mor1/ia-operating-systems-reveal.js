open Mirage

let secrets_key = Key.(value @@ kv_ro ~group:"secrets" ())
let secrets = generic_kv_ro ~key:secrets_key "secrets"

let fs_key = Key.(value @@ kv_ro ())
let assets = generic_kv_ro ~key:fs_key "assets"
let decks = generic_kv_ro ~key:fs_key "ia-operating-systems.wiki"

let port =
  let doc = Key.Arg.info
      ~doc:"Listening port."
      ~docv:"PORT" ~env:"PORT" ["port"]
  in
  Key.(create "port" Arg.(opt int 8080 doc))

let keys = Key.([ abstract port ])

let stackv4 = generic_stackv4 default_network
let http_svr = cohttp_server @@ conduit_direct ~tls:false stackv4

let packages = List.map package [ "magic-mime"; "tyxml"; "markup" ]

let job =
  foreign ~packages ~keys "Unikernel.Http" (
    http @-> kv_ro @-> kv_ro @-> kv_ro @-> job
  )

let () =
  register "lectures" [
     job $ http_svr $ secrets $ assets $ decks
  ]
