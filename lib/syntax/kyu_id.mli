type t = Name of string | Output | Input

val to_string : t -> string
val of_token : Token.t -> t
