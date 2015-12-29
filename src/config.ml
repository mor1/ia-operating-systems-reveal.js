open Mirage

let secrets_dir = "sekrit"

let secrets =
  match get_mode () with
  | `Unix | `MacOSX -> direct_kv_ro secrets_dir
  | `Xen  -> crunch secrets_dir

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
  let ns = Ipaddr.V4.of_string_exn "192.168.3.1" in
  let stack = stack console in
  (conduit_direct ~tls:true stack), (Mirage.resolver_dns ~ns stack)

(* let tracing = mprof_trace ~size:1000000 () *)

let client =
  foreign "Unikernel.Client"
  @@ console @-> clock @-> time @-> resolver @-> conduit @-> kv_ro @-> job

let () =
  let (con, res) = build_stack default_console in
  add_to_opam_packages
    [ "mirage-flow"; "mirage-git"; "mirage-http";
      "decompress"; "irmin"; "github"
    ];
  add_to_ocamlfind_libraries
    [ "irmin"; "irmin.mem"; "irmin.git"; "irmin.mirage";
      "github"; "mirage-http"; "decompress"
    ];
  register (* ~tracing *) "ia.os-lectures"
    [ client $ default_console $ default_clock $ default_time
      $ res $ con $ secrets
    ]
