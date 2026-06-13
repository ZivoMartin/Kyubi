type t =
  | Number of int
  | Operator of Operator.t
  | Ident of string
  | At
  | Dollar
  | Colon
  | Unit
  | Arg of string
  | OpeningBracket
  | ClosingBracket

let to_string = function
  | Number x -> string_of_int x
  | Operator op -> Operator.to_string op
  | Ident name -> name
  | At -> "@"
  | Dollar -> "$"
  | Colon -> ":"
  | Arg name -> Printf.sprintf "'%s" name
  | OpeningBracket -> "{"
  | ClosingBracket -> "}"
  | Unit -> "()"
