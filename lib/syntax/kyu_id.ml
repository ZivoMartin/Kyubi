type t = Name of string | Output | Input

let to_string = function Name s -> s | Output -> "@" | Input -> "$"

let of_token = function
  | Token.At -> Output
  | Token.Dollar -> Input
  | Token.Ident s -> Name s
  | _ ->
      invalid_arg
        "parse_special_queue: takes either a Token.At or Token.Dollar in \
         argument."
