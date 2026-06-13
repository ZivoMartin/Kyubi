type t =
  | Empty
  | Literal of Literal.t
  | Ident of string
  | SQueue of Special_queue.t
  | Behavior of string list * t
  | Flow of t * (Operator.t * t) list
  | Program of t * t

val to_string : t -> string
