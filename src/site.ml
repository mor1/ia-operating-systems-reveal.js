open Tyxml
open Deck

let decks =
  let open Deck in
  [
    Deck.os_ia
      ~given:(Date.t (2018, 02, 16))
      ~title:"[01] Introduction"
      ~description:"A brief introduction to the course"
      ~permalink:"01-Introduction"
      ~venue:Room.MillLane1;

    Deck.os_ia
      ~given:(Date.t (2018, 02, 19))
      ~title:"[02] Protection"
      ~description:"What is the OS protecting?"
      ~permalink:"02-Protection"
      ~venue:Room.MillLane9;

    Deck.os_ia
      ~given:(Date.t (2018, 02, 21))
      ~title:"[03] Processes"
      ~description:"On what does the OS operate?"
      ~permalink:"03-Processes"
      ~venue:Room.MillLane9;

   Deck.os_ia
      ~given:(Date.t (2018, 02, 23))
      ~title:"(STRIKE?) [04] Scheduling"
      ~description:"What does the OS run next?"
      ~permalink:"04-Scheduling"
      ~venue:Room.MillLane9;

   Deck.os_ia
      ~given:(Date.t (2018, 02, 26))
      ~title:"(STRIKE?) [05] Scheduling Algorithms"
      ~description:"How does it choose?"
      ~permalink:"05-Scheduling-Algorithms"
      ~venue:Room.MillLane9;

   Deck.os_ia
      ~given:(Date.t (2018, 02, 28))
      ~title:"(STRIKE?) [06] Virtual Addressing"
      ~description:"How does the OS protect processes from each other?"
      ~permalink:"06-Virtual-Addressing"
      ~venue:Room.MillLane9;

   Deck.os_ia
      ~given:(Date.t (2018, 03, 02))
      ~title:"[07] Paging"
      ~description:"How does the OS manage virtual addresses?"
      ~permalink:"07-Paging"
      ~venue:Room.MillLane9;

   Deck.os_ia
      ~given:(Date.t (2018, 03, 05))
      ~title:"(STRIKE?) [08] Segmentation"
      ~description:"?"
      ~permalink:"08-Segmentation"
      ~venue:Room.MillLane9;

   Deck.os_ia
      ~given:(Date.t (2018, 03, 07))
      ~title:"(STRIKE?) [09] IO Subsystem"
      ~description:"How does the OS interact with the outside world?"
      ~permalink:"09-IO-Subsystem"
      ~venue:Room.MillLane9;

    Deck.os_ia
      ~given:(Date.t (2018, 03, 09))
      ~title:"[10] Storage"
      ~description:"How does the OS manage persistence for processes?"
      ~permalink:"10-Storage"
      ~venue:Room.MillLane9;

    Deck.os_ia
      ~given:(Date.t (2018, 03, 12))
      ~title:"(STRIKE?) [11] Case Study: Unix"
      ~description:"Putting it together I"
      ~permalink:"11-Unix-I"
      ~venue:Room.MillLane9;

    Deck.os_ia
      ~given:(Date.t (2018, 03, 14))
      ~title:"(STRIKE?) [12] Case Study: Unix"
      ~description:"Putting it together II"
      ~permalink:"12-Unix-II"
      ~venue:Room.MillLane9;
  ]

let index () =
  let open Html in
  let script src = script ~a:[a_src src] (txt " ") in
  let link_css ?(a=[]) css = Html.link ~a ~rel:[`Stylesheet] ~href:css () in
  let head =
    head (title (txt "CST IA :: Operating Systems")) [
      meta ~a:[a_charset "utf-8"] ();
      meta ~a:[a_name "viewport"; a_content "width=device-width"] ();
      meta ~a:[a_name "apple-mobile-web-app-capable"; a_content "yes"] ();
      meta ~a:[a_name "apple-mobile-web-app-status-bar-style";
               a_content "black-translucent"] ();
      meta ~a:[a_name "description"; a_content "CUCL IA Operating Systems"] ();

      link_css "/css/foundation.min.css";
      script "/js/vendor/custom.modernizr.js";
      link_css ~a:[a_mime_type "text/css"]
        "http://fonts.googleapis.com/css?family=Source+Sans+Pro:400,600,700";
      link_css ~a:[a_media [`All]] "/css/site.css"
    ]
  in

  let content =
    let deck_to_html d =
      article [
        Deck.Date.to_html d.given;
        h4 [
          a ~a:[a_href (permalink d)] [txt d.title]
        ];
        p [ strong [txt Deck.(Room.to_string d.venue)];
            br ();
            txt d.author
          ];
        p [ br () ]
      ]
    in
    (decks
     |> List.sort Deck.compare
     |> List.map (fun d ->
         li ~a:[a_class ["index-entry"]] [deck_to_html d]
       )
    )
  in

  let body =
    body [
      div ~a:[a_class ["contain-to-grid"]] [
        nav ~a:[a_class ["top-bar"]; a_user_data "topbar" ""] [
          ul ~a:[a_class ["title-area"]] [
            li ~a:[a_class ["name"]] [
              h1 [
                a ~a:[a_id "logo";
                      a_href"http://www.cl.cam.ac.uk/teaching/1516/OpSystems/"
                     ]
                  [
                    img ~src:"http://www.cl.cam.ac.uk/images/identifier.gif"
                    ~alt:"Logo" ()
                ]
              ]
            ]
          ];
          section ~a:[a_class ["top-bar-section"]] []
        ]
      ];
      div ~a:[a_class ["row"]] [
        div ~a:[a_class ["small-12"; "columns"];
                (Unsafe.string_attrib "role" "content")
               ] [
          h2 [
            (txt "Lectures");
          ];
          div ~a:[a_id "index"] [
            ul content
          ]
        ]
      ];

      script "/js/vendor/jquery-2.0.3.min.js";
      script "/js/foundation.min.js";
      script "/js/foundation/foundation.topbar.js";
      Html.script (cdata_script "$(document).foundation();");
      Html.script ~a:[a_mime_type "text/javascript"]
        (pcdata {__|
var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'XX-XXXXXXXX-X']);
_gaq.push(['_trackPageview']);

(function() {
  var ga = document.createElement('script');
  ga.type = 'text/javascript';
  ga.async = true;
  ga.src =
    ('https:' == document.location.protocol ? 'https://ssl' : 'http://www')
    + '.google-analytics.com/ga.js';
  var s = document.getElementsByTagName('script')[0];
  s.parentNode.insertBefore(ga, s);
})();
|__}
        )
    ]
  in

  Lwt.return (Render.to_string @@ Html.html ~a:[Html.a_lang "en"] head body)

let lecture ~lecture =
  decks
  |> List.find (fun d -> d.Deck.permalink = lecture)
  |> Revealjs330.page
