type 'v map = (string, 'v) Hashtbl.t

type 'v t = {
  mutable pattern_bindings : 'v map;
  mutable args_bindings : 'v map;
}

val create : unit -> 'v t
val add_pat_binding : 'v t -> string -> 'v -> unit
val add_arg_binding : 'v t -> string -> 'v -> unit
val set_pat : 'v t -> 'v map -> unit
val set_args : 'v t -> 'v map -> unit
val get : 'v t -> string -> 'v option
