type t =
  | Number of int
  | Unit
  | Behavior of string list * Ast.t
  | BuiltinBehavior of Builtin.t * t Kyu.apply

val to_string : t -> string
val of_string : string -> t
val equal : t -> t -> bool
val of_literal : t Bindings.t option -> Literal.t -> t
val to_literal : t -> Literal.t option
val activate_builtin : Builtin.t -> t Behavior.t
val matches : Pattern.t -> t -> bool
