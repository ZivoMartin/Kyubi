type flow = t * (Operator.t * t) list

and t =
  | Empty
  | Literal of Literal.t
  | Kyu of Kyu_id.t
  | Behavior of string list * t
  | Flow of flow
  | Program of t * t
  | Branching of (Pattern.t * flow) list

val to_string : t -> string
