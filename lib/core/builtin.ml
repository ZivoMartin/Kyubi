open Value

(*
  How to add a builtin:
  - Add one variant in the type t
  - Add one case in from_string_opt
  - Add one case in process
  - Add the variant in get_all
  - Follow compilation errors for the rest
 *)

type t = Add | Sub | Print | Println

exception InvalidNumberArgs of int * int

let from_string_opt = function
  | "+" -> Some Add
  | "-" -> Some Sub
  | "!print" -> Some Print
  | "!println" -> Some Println
  | s -> None

let from_string s =
  match from_string_opt s with
  | Some builtin -> builtin
  | None ->
      invalid_arg (Printf.sprintf "operator_of_string: invalid operator %S" s)

let to_string = function
  | Add -> "+"
  | Sub -> "-"
  | Print -> "!print"
  | Println -> "!println"

let get_all () = [ Add; Sub; Print; Println ]
let get_all_string () = List.map to_string (get_all ())
let number_of_arg = function Add -> 2 | Sub -> 2 | Print -> 1 | Println -> 1

let process builtin args =
  match (builtin, args) with
  | Add, [ Value.Number x1; Value.Number x2 ] -> Value.Number (x1 + x2)
  | Sub, [ Value.Number x1; Value.Number x2 ] -> Value.Number (x1 - x2)
  | Print, [ x ] ->
      print_string (Value.to_string x);
      Value.Unit
  | Println, [ x ] ->
      print_endline (Value.to_string x);
      Value.Unit
  | _ -> raise (InvalidNumberArgs (number_of_arg builtin, List.length args))
