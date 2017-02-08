open Sexplib.Conv
open Sexplib.Std

module Date = struct
  type t = {
    year: int;
    month: int;
    day: int;
  } with xml, sexp

  let t (year, month, day) = { year; month; day }

  let to_html d =
    let _xml_of_month m =
      let _str = match m with
        | 1  -> "Jan" | 2  -> "Feb" | 3  -> "Mar" | 4  -> "Apr"
        | 5  -> "May" | 6  -> "Jun" | 7  -> "Jul" | 8  -> "Aug"
        | 9  -> "Sep" | 10 -> "Oct" | 11 -> "Nov" | 12 -> "Dec"
        | _  -> "???" in
      <:xml< $str:_str$ >>
    in
    <:xml<
        <div class="date">
          <div class="month">$_xml_of_month d.month$</div>
          <div class="day">$int:d.day$</div>
          <div class="year">$int:d.year$</div>
        </div>
      >>

  let compare {year=ya;month=ma;day=da} {year=yb;month=mb;day=db} =
    match ya - yb with
    | 0 -> (match ma - mb with
        | 0 -> da - db
        | n -> n
      )
    | n -> n

end

module Room = struct
  type t = ArtsA | MillLane with sexp

  let to_string = function
    | ArtsA -> "Arts School, Room A"
    | MillLane -> "Mill Lane, Room 1"

end

module Course = struct
  type t = IA_OS with sexp

  let to_string = function
    | IA_OS -> "IA Operating Systems"

  let to_prefix = function
    | IA_OS -> "ia-os/"

end

type t = {
  course: Course.t;
  venue: Room.t;
  given: Date.t;
  author: string;
  title: string;
  description: string;
  permalink: string;
} with sexp

let os_ia ~given ~title ~description ~permalink =
  { course=Course.IA_OS; venue=Room.MillLane; author="Dr Richard Mortier";
    given; title; description; permalink
  }

let permalink d = (Course.to_prefix d.course) ^ d.permalink
let compare a b = Date.compare b.given a.given
let to_string t = t |> sexp_of_t |> Sexplib.Sexp.to_string_hum
