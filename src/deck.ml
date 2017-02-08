open Tyxml.Html

module Date = struct
  type t = {
    year: int;
    month: int;
    day: int;
  }

  let t (year, month, day) = { year; month; day }

  let to_html d =
    let string_of_month = function
      | 1  -> "Jan" | 2  -> "Feb" | 3  -> "Mar" | 4  -> "Apr"
      | 5  -> "May" | 6  -> "Jun" | 7  -> "Jul" | 8  -> "Aug"
      | 9  -> "Sep" | 10 -> "Oct" | 11 -> "Nov" | 12 -> "Dec"
      | _  -> "???"
    in
    div ~a:[a_class ["date"]] [
      div ~a:[a_class ["month"]] [ pcdata (string_of_month d.month) ];
      div ~a:[a_class ["day"]] [ pcdata (string_of_int d.day) ] ;
      div ~a:[a_class ["year"]] [ pcdata (string_of_int d.year) ] ;
    ]

  let compare {year=ya;month=ma;day=da} {year=yb;month=mb;day=db} =
    match ya - yb with
    | 0 -> (match ma - mb with
        | 0 -> da - db
        | n -> n
      )
    | n -> n

end

module Room = struct
  type t = ArtsA | MillLane

  let to_string = function
    | ArtsA -> "Arts School, Room A"
    | MillLane -> "Mill Lane, Room 1"

end

module Course = struct
  type t = IA_OS

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
}

let os_ia ~given ~title ~description ~permalink =
  { course=Course.IA_OS;
    venue=Room.MillLane;
    author="Dr Richard Mortier";
    given;
    title;
    description;
    permalink
  }

let permalink d = (Course.to_prefix d.course) ^ d.permalink
let compare a b = Date.compare a.given b.given
