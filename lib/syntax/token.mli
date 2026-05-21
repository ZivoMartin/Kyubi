open Operator

type token = Number of int | Operator of operator | Ident of string

val string_of_token : token -> string
