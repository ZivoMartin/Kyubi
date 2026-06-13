type t = Absent | All | Const of int

val to_string : t -> string
val of_string : string -> t
