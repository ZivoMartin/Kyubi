type t = { p1 : Position.t; p2 : Position.t }

val create : Position.t -> Position.t -> t
val to_string : t -> string
