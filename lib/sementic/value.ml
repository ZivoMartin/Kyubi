exception InvalidNumberArgs of int * int
exception TypeErrorInBuiltin

type t =
  | Number of int
  | Unit
  | Behavior of string list * Ast.t
  | BuiltinBehavior of Builtin.t * t Apply.t

let of_literal args l =
  match l with
  | Literal.Number x -> Number x
  | Literal.Unit -> Unit
  | Literal.Arg name -> (
      match args with
      | Some args -> (
          match Hashtbl.find_opt args name with
          | Some x -> x
          | None -> failwith (Printf.sprintf "Unbound argument : %s" name))
      | None -> failwith "Arguments are only available inside beahviors")

let to_literal = function
  | Number x -> Some (Literal.Number x)
  | Unit -> Some Literal.Unit
  | Behavior _ -> None
  | BuiltinBehavior _ -> None

let to_string = function
  | Number x -> string_of_int x
  | Unit -> "()"
  | Behavior (args, ast) -> Ast.to_string (Ast.Behavior (args, ast))
  | BuiltinBehavior (b, _) -> Builtin.to_string b

let of_string s = Literal.of_string s |> of_literal None

let equal v1 v2 =
  match (v1, v2) with
  | Number x1, Number x2 -> x1 = x2
  | Unit, Unit -> true
  | _ -> false

let activate_builtin b =
  let fetch_args args =
    Builtin.build_args b
    |> List.map (fun a -> Hashtbl.find_opt args a)
    |> Option_utils.flatten
    |> Option_utils.unwrap_or_raise (Failure "Failed to parse args")
  in

  let impl =
    match b with
    | Add -> (
        fun args ->
          let args = fetch_args args in
          match args with
          | [ Number x1; Number x2 ] -> [ Number (x1 + x2) ]
          | _ -> raise TypeErrorInBuiltin)
    | Sub -> (
        fun args ->
          let args = fetch_args args in
          match args with
          | [ Number x1; Number x2 ] -> [ Number (x2 - x1) ]
          | _ -> raise TypeErrorInBuiltin)
    | Print -> (
        fun args ->
          let args = fetch_args args in
          match args with
          | [ x ] ->
              print_string (to_string x);
              [ Unit ]
          | _ -> raise TypeErrorInBuiltin)
    | Println -> (
        fun args ->
          let args = fetch_args args in
          match args with
          | [ x ] ->
              print_endline (to_string x);
              [ Unit ]
          | _ -> raise TypeErrorInBuiltin)
  in
  Behavior.Builtin
    (b, fun args output -> impl args |> List.to_seq |> Queue.add_seq output)
