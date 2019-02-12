open Tyxml
open Deck

let page d =
  let head =
    let link_css ?(a=[]) css = Html.link ~a ~rel:[`Stylesheet] ~href:css () in

    let open Html in
    head (title (txt d.title)) [
      meta ~a:[a_charset "utf-8"] ();
      meta ~a:[a_name "description"; a_content d.description] ();
      meta ~a:[a_name "author"; a_content d.author] ();

      meta ~a:[a_name "apple-mobile-web-app-capable"; a_content "yes"] ();
      meta ~a:[a_name "apple-mobile-web-app-status-bar-style";
               a_content "black-translucent"] ();

      meta ~a:[a_name "viewport";
               a_content "width=device-width, initial-scale=1.0,\
                          maximum-scale=1.0, user-scalable=no, minimal-ui"] ();

      link_css "/reveal.js-3.3.0/css/reveal.min.css";
      link_css ~a:[a_id "theme"] ("/reveal.js-3.3.0/css/theme/white.css");
      link_css "/highlight.js-9.9.0/styles/zenburn.min.css";

      script (txt {__|
        var link = document.createElement('link');
        link.rel = 'stylesheet';
        link.type = 'text/css';
        link.href = '/reveal.js-3.3.0/'+
          (window.location.search.match(/print-pdf/gi) ?
            'css/print/pdf.css' : 'css/print/paper.css');
        document.getElementsByTagName('head')[0].appendChild( link );
      |__});

      link_css "/css/site.css";

      (Xml.comment
         {__|[if lt IE 9]
             <script src="/reveal.js-3.3.0/lib/js/html5shiv.js"> </script>
             <![endif]|__}
       |> tot)
    ]
  in

  let body =
    let open Html in
    let script s = script ~a:[a_src s] (txt " ") in
    body [
      div ~a:[a_class ["reveal"]] [
        div ~a:[a_class ["slides"]] [
          section ~a:[a_user_data "markdown" (d.permalink^".md");
                      a_user_data "separator" "^\n\n----\n";
                      a_user_data "separator-vertical" "^\n\n";
                      a_user_data "notes" "^Note:";
                      a_user_data "charset" "iso-8859-15"] [
          ];

          div ~a:[a_id "footer"] [
            a ~a:[a_id "index"; a_href "/"] [
              img ~src:"/img/home.png" ~alt:"Home" ()
            ];
            a ~a:[a_id "print-pdf"; a_href "?print-pdf"] [
              img ~src:"/img/print.png" ~alt:"Print" ()
            ]
          ]
        ]
      ];

      script "/reveal.js-3.3.0/lib/js/head.min.js";
      script "/reveal.js-3.3.0/js/reveal.min.js";
      script "/js/init.js";
    ]
  in
  Lwt.return (Render.to_string @@ Html.html head body)
