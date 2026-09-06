type t = Number of int | Unit | RuntimeVal of string

val to_string : t -> string
val of_string : string -> t
