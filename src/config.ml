open Mirage

let _kv_ro d = match get_mode () with
  | `Unix | `MacOSX -> direct_kv_ro d
  | `Xen  -> crunch d

let secrets = _kv_ro "secrets"
let assets = _kv_ro "assets"
let decks = _kv_ro "../ia-operating-systems.wiki"

let stack console =
  let net =
    try match Sys.getenv "NET" with
      | "direct" -> `Direct
      | _ -> `Socket
    with Not_found -> match get_mode () with
      | `Unix | `MacOSX -> `Socket
      | `Xen -> `Direct
  in
  match net with
  | `Direct -> direct_stackv4_with_dhcp console tap0
  | `Socket -> socket_stackv4 console [Ipaddr.V4.any]

let build_stack console =
  let ns = Ipaddr.V4.of_string_exn "8.8.8.8" in
  let stack = stack console in
  (conduit_direct ~tls:true stack), (Mirage.resolver_dns ~ns stack)

(* let tracing = mprof_trace ~size:1000000 () *)

let client =
  foreign "Unikernel.Client"
  @@ console @-> clock @-> time
     @-> resolver @-> conduit @-> http @-> kv_ro @-> kv_ro @-> kv_ro @-> job

let () =
  let (conduit, resolver) = build_stack default_console in
  let http_srv = http_server conduit in
  add_to_opam_packages
    [ "mirage-flow"; "mirage-git"; "mirage-http"; "astring";
      "decompress"; "irmin"; "github"; "cow"; "cowabloga"
    ];
  add_to_ocamlfind_libraries
    [ "irmin"; "irmin.mem"; "irmin.git"; "irmin.mirage";
      "github"; "mirage-http"; "decompress"; "cow.syntax"; "cowabloga";
      "sexplib"; "sexplib.syntax"; "astring"
    ];
  register (* ~tracing *) "lectures"
    [ client $ default_console $ default_clock $ default_time
      $ resolver $ conduit $ http_srv $ secrets $ assets $ decks
    ]
