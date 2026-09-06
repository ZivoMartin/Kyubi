type t = Number of int | Unit | RuntimeVal of string

let to_string = function
  | Number x -> string_of_int x
  | Unit -> "()"
  | RuntimeVal name -> Printf.sprintf "'%s" name
