type t =
  | Empty
  | Literal of Literal.t
  | Ident of string
  | SQueue of Special_queue.t
  | Behavior of string list * t
  | Flow of t * (Operator.t * t) list
  | Program of t * t

let rec to_string = function
  | Empty -> ""
  | Literal l -> Literal.to_string l
  | SQueue q -> Special_queue.to_string q
  | Ident name -> name
  | Behavior (args, body) ->
      Printf.sprintf "{ %s : %s }"
        (args |> List.map (fun a -> Printf.sprintf "'%s" a) |> String.concat " ")
        (to_string body)
  | Flow (left, right) ->
      right
      |> List.map (fun (op, body) ->
          Printf.sprintf "%s %s" (Operator.to_string op) (to_string body))
      |> String.concat " "
      |> Printf.sprintf "%s %s" (to_string left)
  | Program (left, right) ->
      Printf.sprintf "%s\n%s" (to_string left) (to_string right)
