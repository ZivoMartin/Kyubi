open Value

type t = Add | Sub | Print | Println

val from_string_opt : string -> t option
val from_string : string -> t
val to_string : t -> string
val get_all : unit -> t list
val get_all_string : unit -> string list
val number_of_arg : t -> int
val process : t -> Value.t list -> Value.t
