exception NotEnoughElementInEntryQueue

type ('v, 'b) production = { behavior : 'b; output : 'v Queue.t }
type ('v, 'b) t = { entry : 'v Queue.t; prod : ('v, 'b) production Queue.t }

val enqueue : ('v, 'b) t -> 'v -> unit
val dequeue : ('v, 'b) t -> 'v option
val create : unit -> ('v, 'b) t
val enqueue_behavior : ('v, 'b) t -> 'b -> unit
val dequeue_behavior : ('v, 'b) t -> ('v, 'b) production option
val equal : ('v -> 'v -> bool) -> ('v, 'b) t -> ('v, 'b) t -> bool
val is_empty : ('v, 'b) t -> bool
val entry_is_empty : ('v, 'b) t -> bool
val output_is_empty : ('v, 'b) t -> bool
val of_string : 'b -> (string -> 'v) -> string -> ('v, 'b) t
val to_string : ('v -> string) -> ('v, 'b) t -> string
val of_list : 'v list -> ('v, 'b) t
val output_length : ('v, 'b) t -> int
val entry_length : ('v, 'b) t -> int
val produce : ('v, 'b) t -> ('b -> 'v Apply.t) -> ('b -> string list) -> unit
