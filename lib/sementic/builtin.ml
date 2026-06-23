type t = Add | Sub | Print | Println

let from_string_opt = function
  | "+" -> Some Add
  | "-" -> Some Sub
  | "!print" -> Some Print
  | "!println" -> Some Println
  | _ -> None

let from_string s =
  match from_string_opt s with
  | Some builtin -> builtin
  | None ->
      invalid_arg (Printf.sprintf "builtin.from_string: invalid builtin %S" s)

let to_string = function
  | Add -> "+"
  | Sub -> "-"
  | Print -> "!print"
  | Println -> "!println"

let get_all () = [ Add; Sub; Print; Println ]
let get_all_string () = List.map to_string (get_all ())
let get_n = function Add -> 2 | Sub -> 2 | Print -> 1 | Println -> 1
