type t = Number of int | Unit | Arg of string

let to_string = function
  | Number x -> string_of_int x
  | Unit -> "()"
  | Arg name -> Printf.sprintf "'%s" name

let of_string = function
  | "()" -> Unit
  | s ->
      let fail () =
        invalid_arg (Printf.sprintf "value_of_string: invalid value %S" s)
      in

      if String.starts_with ~prefix:"'" s then
        let arg = String.length s |> String.sub s 1 in
        if String_utils.is_valid_ident arg then Arg arg else fail ()
      else Number (int_of_string_opt s |> Option_utils.unwrap_or_else fail)
