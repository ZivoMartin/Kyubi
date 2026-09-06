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

val to_string : t -> string
