open Operator

type token = Number of int | Operator of operator | Ident of string

let string_of_token = function
  | Number x -> Printf.sprintf "Number: %d" x
  | Operator op -> Printf.sprintf "operator: %s" (string_of_operator op)
  | Ident name -> Printf.sprintf "Ident: %s" name
