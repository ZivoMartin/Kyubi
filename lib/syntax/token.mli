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

val to_string : t -> string
