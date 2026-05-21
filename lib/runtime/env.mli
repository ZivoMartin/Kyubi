open Value

type env = { queues : (string, Value.t Queue.t) Hashtbl.t }

val create : unit -> env
val enqueue : env -> string -> Value.t -> unit
val dequeue_in : env -> string -> string -> unit
val env_of_string : string -> env
val string_of_env : env -> string
val equal : env -> env -> bool
val dequeue : env -> string -> Value.t
val dequeue_n : env -> string -> int -> Value.t list
val dequeue_n_in : env -> int -> string -> string -> unit
val dequeue_all_in : env -> string -> string -> unit
val produce_n_in : env -> int -> string -> string -> unit
val produce_in : env -> string -> string -> unit
