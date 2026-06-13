type 'v t =
  | Defined of string list * Ast.t * 'v Apply.t
  | Builtin of Builtin.t * 'v Apply.t

let default_behavior = Defined ([], Ast.Empty, fun _ _ -> ())

let get_args = function
  | Defined (args, _, _) -> args
  | Builtin (b, _) -> Builtin.build_args b

let process = function Defined (_, _, f) -> f | Builtin (_, f) -> f
