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

val to_string : t -> string
