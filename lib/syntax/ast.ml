type flow = t * (Operator.t * t) list

and t =
  | Empty
  | Literal of Literal.t
  | Kyu of Kyu_id.t
  | Behavior of string list * t
  | Flow of flow
  | Program of t * t
  | Branching of (Pattern.t * flow) list

let rec to_string = function
  | Empty -> ""
  | Literal l -> Literal.to_string l
  | Kyu k -> Kyu_id.to_string k
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
  | Branching branches ->
      branches
      |> List.map (fun (pat, flow) ->
          Printf.sprintf "| %s %s\n" (Pattern.to_string pat)
            (to_string (Flow flow)))
      |> String.concat " "
