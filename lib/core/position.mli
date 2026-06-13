type t = { line : int; column : int }

val advance : t -> char -> t
val create : int -> int -> t
val start : unit -> t
val to_string : t -> string
