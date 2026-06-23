type t =
  | Number of int
  | Operator of Operator.t
  | Ident of string
  | At
  | Dollar
  | Colon
  | Comma
  | Unit
  | Bar
  | Arg of string
  | OpeningBracket
  | OpeningSBracket
  | ClosingBracket
  | ClosingSBracket

let to_string = function
  | Number x -> string_of_int x
  | Operator op -> Operator.to_string op
  | Ident name -> name
  | At -> "@"
  | Dollar -> "$"
  | Bar -> "|"
  | Colon -> ":"
  | Comma -> ","
  | Arg name -> Printf.sprintf "'%s" name
  | OpeningBracket -> "{"
  | OpeningSBracket -> "["
  | ClosingBracket -> "}"
  | ClosingSBracket -> "]"
  | Unit -> "()"
