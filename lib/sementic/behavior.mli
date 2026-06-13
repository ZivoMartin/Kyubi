type 'v t =
  | Defined of string list * Ast.t * 'v Apply.t
  | Builtin of Builtin.t * 'v Apply.t

val default_behavior : 'v t
val get_args : 'v t -> string list
val process : 'v t -> 'v Apply.t
