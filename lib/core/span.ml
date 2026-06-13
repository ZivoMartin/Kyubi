type t = { p1 : Position.t; p2 : Position.t }

let create p1 p2 = { p1; p2 }

let to_string span =
  Printf.sprintf "%s-%s"
    (Position.to_string span.p1)
    (Position.to_string span.p2)
