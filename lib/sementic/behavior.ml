type 'v t =
  | Defined of string list * Ast.t * 'v Kyu.apply
  | Builtin of Builtin.t * 'v Kyu.apply

let default_behavior = Defined ([], Ast.Empty, fun _ _ _ -> ())
let get_args = function Defined (args, _, _) -> args | Builtin _ -> []
let process = function Defined (_, _, f) -> f | Builtin (_, f) -> f
