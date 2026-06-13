type t = Output | Input

let to_string = function Output -> "@" | Input -> "$"

let of_token = function
  | Token.At -> Output
  | Token.Dollar -> Input
  | _ ->
      invalid_arg
        "parse_special_queue: takes either a Token.At or Token.Dollar in \
         argument."
