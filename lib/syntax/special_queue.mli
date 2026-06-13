type t = Output | Input

val to_string : t -> string
val of_token : Token.t -> t
