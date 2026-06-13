type t = Absent | All | Const of int

let to_string = function
  | Absent -> ""
  | All -> "_"
  | Const n -> string_of_int n

let of_string = function
  | "" -> Absent
  | "_" -> All
  | s ->
      Const
        (int_of_string_opt s
        |> Option_utils.unwrap_or_else (fun () ->
            invalid_arg (Printf.sprintf "Invalid flow size %S" s)))
