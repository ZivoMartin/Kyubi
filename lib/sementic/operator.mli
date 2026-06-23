type t =
  | Enqueue of Flow_size.t
  | Produce of Flow_size.t * Flow_size.t
  | Benqueue of Flow_size.t
  | Promote of Flow_size.t
  | Demote of Flow_size.t
  | Dup of Flow_size.t

val to_string : t -> string
val of_string : string -> t
val is_body_char : char -> bool
