open Lwt
open Cow
open Cowabloga
open Sexplib.Conv
open Sexplib.Std

let decks =
  let open Deck in
  [
    Deck.os_ia
      ~given:(Date.t (2016, 03, 09))
      ~title:"[00] Corrections"
      ~description:"Corrections"
      ~permalink:"00-Corrections";

    Deck.os_ia
      ~given:(Date.t (2016, 02, 12))
      ~title:"[01] Introduction"
      ~description:"A brief introduction to the course"
      ~permalink:"01-Introduction";

    Deck.os_ia
      ~given:(Date.t (2016, 02, 15))
      ~title:"[02] Protection"
      ~description:"What is the OS protecting?"
      ~permalink:"02-Protection";

    Deck.os_ia
      ~given:(Date.t (2016, 02, 17))
      ~title:"[03] Processes"
      ~description:"On what does the OS operate?"
      ~permalink:"03-Processes";

   Deck.os_ia
      ~given:(Date.t (2016, 02, 19))
      ~title:"[04] Scheduling"
      ~description:"What does the OS run next?"
      ~permalink:"04-Scheduling";

   Deck.os_ia
      ~given:(Date.t (2016, 02, 22))
      ~title:"[05] Virtual Addressing"
      ~description:"How does the OS protect processes from each other?"
      ~permalink:"05-Virtual-Addressing";

   Deck.os_ia
      ~given:(Date.t (2016, 02, 24))
      ~title:"[06] Paging"
      ~description:"How does the OS manage virtual addresses?"
      ~permalink:"06-Paging";

   Deck.os_ia
      ~given:(Date.t (2016, 02, 26))
      ~title:"[07] Segmentation"
      ~description:"?"
      ~permalink:"07-Segmentation";

   Deck.os_ia
      ~given:(Date.t (2016, 02, 29))
      ~title:"[08] IO Subsystem"
      ~description:"How does the OS interact with the outside world?"
      ~permalink:"08-IO-Subsystem";

    Deck.os_ia
      ~given:(Date.t (2016, 03, 02))
      ~title:"[09] Storage"
      ~description:"How does the OS manage persistence for processes?"
      ~permalink:"09-Storage";

    Deck.os_ia
      ~given:(Date.t (2016, 03, 04))
      ~title:"[10] Communication"
      ~description:"How does the OS manage communication between processes?"
      ~permalink:"10-Communication";

    Deck.os_ia
      ~given:(Date.t (2016, 03, 07))
      ~title:"[11] Case Study: Unix"
      ~description:"Putting it together I"
      ~permalink:"11-Unix";

    Deck.os_ia
      ~given:(Date.t (2016, 03, 09))
      ~title:"[12] Case Study: Windows NT"
      ~description:"Putting it together II?"
      ~permalink:"12-WindowsNT";
  ]

let index () =
  let _content =
    let _lectures =
      decks |> List.sort Deck.compare |> List.rev |> List.map (
          fun d ->
            <:html<
              <article>
                $Deck.(Date.to_html d.given)$
                <h4><a href="$str:Deck.permalink d$">
                  $str:d.Deck.title$
                </a></h4>
                <p>
                  <strong>$str:Deck.(Room.to_string d.venue)$</strong>;
                  Dr Richard Mortier
                </p>
                <p><br /></p>
              </article>
            >>)
    in <:html< <ul>$list:_lectures$</ul> >>
  in
  let body =
    <:html<
      <html lang="en">
        <head>
          <meta charset="utf-8"/>
          <meta name="viewport" content="width=device-width"/>
          <meta name="apple-mobile-web-app-capable" content="yes" />
          <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />

          <title>CST IA :: Operating Systems</title>
          <meta name="description" content="CUCL IA Operating Systems" />

          <link rel="stylesheet" href="/css/vendor/foundation.min.css"> </link>
          <script src="/js/vendor/custom.modernizr.js"> </script>
          <link href="http://fonts.googleapis.com/css?family=Source+Sans+Pro:400,600,700"
                rel="stylesheet" type="text/css"> </link>
          <link rel="stylesheet" href="/css/site.css" media="all"> </link>

        </head>
        <body>
          <div class="contain-to-grid fixed">
            <nav class="top-bar" data-topbar="">
              <ul class="title-area">
                <li class="name">
                  <h1><a id="logo"
                         href="http://www.cl.cam.ac.uk/teaching/1516/OpSystems/">
                    <img src="http://www.cl.cam.ac.uk/images/identifier.gif"
                         alt="Logo" />
                  </a></h1>
                </li>
              </ul>
              <section class="top-bar-section" />
            </nav>
          </div>

          <div class="row"><div class="small-12 columns" role="content">
            <h2>Lectures</h2>
            <div id="index">
              $_content$
              <br/>
            </div>
          </div></div>

          <script src="/js/vendor/jquery-2.0.3.min.js"> </script>
          <script src="/js/vendor/foundation.min.js"> </script>
          <script src="/js/vendor/foundation.topbar.js"> </script>
          <script> <![CDATA[ $(document).foundation(); ]]> </script>
          <script type="text/javascript">
            var _gaq = _gaq || [];
            _gaq.push(['_setAccount', 'XX-XXXXXXXX-X']);
            _gaq.push(['_trackPageview']);

            (function() {
              var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
              ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
              var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
            })();
          </script>
        </body>
      </html>
    >>
  in
  return (Fragments.preamble ^ (Foundation.page ~body) ^ Fragments.postamble)

let lecture ~lecture =
  let d = List.find (fun d -> d.Deck.permalink = lecture) decks in
  Revealjs320.page d
