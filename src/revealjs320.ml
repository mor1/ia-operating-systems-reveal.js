open Lwt
open Cow

let meta ~d =
  <:html<
      <meta charset="utf-8" />
      <title>$str:d.Deck.title$</title>
      <meta name="description" content="$str:d.Deck.description$" />
      <meta name="author" content="$str:d.Deck.author$" />

      <meta name="apple-mobile-web-app-capable" content="yes" />
      <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />

      <meta name="viewport"
        content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, minimal-ui" />
  >>

let links ~revealv =
  let _reveal_link link = revealv ^ link in
  let _css_link ?id href =
    let _id = match id with None -> "" | Some id -> "id=\""^id^"\"" in
    <:html<
      <link rel="stylesheet" href="$str:href$"> </link>
    >>
  in
  let _css_link_with_id id href = _css_link ~id href in
  <:html<
    $_css_link (_reveal_link "/css/reveal.min.css")$
    $_css_link_with_id "theme" (_reveal_link "/css/theme/white.css")$

    <!-- code syntax highlighting -->
    $_css_link "/highlight.js-9.1.0/styles/zenburn.min.css"$
  >>

let scripts ~revealv =
  <:html<
    <!-- Printing and PDF exports -->
    <script>
      var link = document.createElement('link');
      link.rel = 'stylesheet';
      link.type = 'text/css';
      link.href = '$str:revealv$/' +
        (window.location.search.match(/print-pdf/gi) ?
          'css/print/pdf.css' : 'css/print/paper.css');
      document.getElementsByTagName('head')[0].appendChild( link );
    </script>
  >>

let head ~revealv ~d =
  <:html<
    <head>
      $meta ~d$

      <base href=$str:d.Deck.permalink$ />

      $links ~revealv$

      $scripts ~revealv$

      <!-- local overrides -->
      <link rel="stylesheet" href="/css/site.css"/>

      <!--[if lt IE 9]>
           <script src="$str:revealv$/lib/js/html5shiv.js"> </script>
      <![endif]-->
    </head>
  >>

let slides ~d =
  <:html<
    <div class="reveal">
      <div class="slides">
        <section data-markdown="$str:d.Deck.permalink^".md"$"
          data-separator="^\n\n----\n"
          data-separator-vertical="^\n\n"
          data-notes="^Note:"
          data-charset="iso-8859-15">
        </section>

        <div id="footer">
          <a id="index" href="/"> <img src="/img/home.png" /> </a>
          <a id="print-pdf" href="?print-pdf"> <img src="/img/print.png" /> </a>
        </div>

      </div>
    </div>
  >>

let body ~revealv ~d =
  let _script href = <:html< <script src="$str:href$"> </script> >> in
  let _reveal_script href = _script (revealv^href) in
  <:html<
    <body>
      $slides ~d$

      $_reveal_script "/lib/js/head.min.js"$
      $_reveal_script "/js/reveal.min.js"$
      $_script "/js/init.js"$
    </body>
    >>

let page d =
  let _revealv = "/reveal.js-3.2.0" in
  return (
    Cow.Html.to_string
      <:html<
        $head _revealv d$
        $body _revealv d$
      >>
  )
