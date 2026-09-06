type flow = t * (Operator.t * t) list

and t =
  | Empty
  | Literal of Literal.t
  | Kyu of Kyu_id.t
  | Behavior of string list * t
  | Flow of flow
  | Program of t * t
  | Branching of (Pattern.t * t list) list

let rec of_list cast = function
  | [] -> Empty
  | a :: rest -> Program (cast a, of_list cast rest)

let rec to_string = function
  | Empty -> ""
  | Literal l -> Literal.to_string l
  | Kyu k -> Kyu_id.to_string k
  | Behavior (args, body) ->
      Printf.sprintf " (Behavior) { %s : %s }"
        (args |> List.map (fun a -> Printf.sprintf "'%s" a) |> String.concat " ")
        (to_string body)
  | Flow (left, right) ->
      right
      |> List.map (fun (op, body) ->
          Printf.sprintf "%s %s" (Operator.to_string op) (to_string body))
      |> String.concat " "
      |> Printf.sprintf "(Flow) %s %s" (to_string left)
  | Program (left, right) ->
      Printf.sprintf "(Program) %s\n%s" (to_string left) (to_string right)
  | Branching branches ->
      branches
      |> List.map (fun (pat, flows) ->
          flows
          |> List.map (fun f -> to_string f)
          |> String.concat "\n"
          |> Printf.sprintf "(Branching) | %s %s\n" (Pattern.to_string pat))
      |> String.concat " "
