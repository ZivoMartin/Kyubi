type t =
  | Number of int
  | Operator of Operator.t
  | Ident of string
  | At
  | Dollar
  | Colon
  | Comma
  | Bar
  | Gt
  | RuntimeVal of string
  | OpeningBracket
  | OpeningSBracket
  | ClosingBracket
  | ClosingSBracket
  | OpeningPar
  | ClosingPar

let to_string = function
  | Number x -> string_of_int x
  | Operator op -> Operator.to_string op
  | Ident name -> name
  | At -> "@"
  | Dollar -> "$"
  | Bar -> "|"
  | Gt -> ">"
  | Colon -> ":"
  | Comma -> ","
  | RuntimeVal name -> Printf.sprintf "'%s" name
  | OpeningBracket -> "{"
  | OpeningSBracket -> "["
  | ClosingBracket -> "}"
  | ClosingSBracket -> "]"
  | OpeningPar -> "("
  | ClosingPar -> ")"
