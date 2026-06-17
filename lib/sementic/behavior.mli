type 'v t =
  | Defined of string list * Ast.t * 'v Kyu.apply
  | Builtin of Builtin.t * 'v Kyu.apply

val default_behavior : 'v t
val get_args : 'v t -> string list
val process : 'v t -> 'v Kyu.apply
