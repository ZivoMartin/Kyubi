type t = { line : int; column : int }

let advance pos = function
  | '\n' -> { column = 1; line = pos.line + 1 }
  | _ -> { column = pos.column + 1; line = pos.line }

let create line column = { line; column }
let start () = { line = 1; column = 1 }
let to_string pos = Printf.sprintf "%d:%d" pos.line pos.column
