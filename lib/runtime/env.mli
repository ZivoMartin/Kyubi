type t = { kyus : (string, (Value.t, Value.t Behavior.t) Kyu.t) Hashtbl.t }

val create : unit -> t
val enqueue : t -> string -> Value.t -> unit
val env_of_string : string -> t
val string_of_env : t -> string
val equal : t -> t -> bool
val dequeue_in : t -> string -> string -> Flow_size.t -> unit
val produce_in : t -> string -> string -> Flow_size.t -> Flow_size.t -> unit

val produce_in_this_queue :
  t -> string -> Value.t Queue.t -> Flow_size.t -> Flow_size.t -> unit

val enqueue_behavior : t -> string -> Value.t Behavior.t -> unit
val dequeue_behavior_in : t -> string -> string -> Flow_size.t -> unit

val promote_in :
  t ->
  (Value.t -> Value.t Behavior.t) ->
  string ->
  string ->
  Flow_size.t ->
  unit

val demote_in :
  t ->
  (Value.t Behavior.t -> Value.t) ->
  string ->
  string ->
  Flow_size.t ->
  unit
