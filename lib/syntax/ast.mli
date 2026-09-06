type flow = t * (Operator.t * t) list

and t =
  | Empty
  | Literal of Literal.t
  | Kyu of Kyu_id.t
  | Behavior of string list * t
  | Flow of flow
  | Program of t * t
  | Branching of (Pattern.t * t list) list

val to_string : t -> string
val of_list : ('a -> t) -> 'a list -> t
