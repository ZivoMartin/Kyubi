open Option_utils

type t = Number of int | Unit

let to_string = function Number x -> string_of_int x | Unit -> "()"

let of_string = function
  | "()" -> Unit
  | s ->
      Number
        (int_of_string_opt s
        |> Option_utils.unwrap_or_else (fun () ->
            invalid_arg (Printf.sprintf "value_of_string: invalid value %S" s))
        )
