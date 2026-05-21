open Operator
open Token
open Value

type ast =
  | Value of Value.t
  | Ident of string
  | Flow of ast * (operator * ast) list
  | Program of ast * ast option
