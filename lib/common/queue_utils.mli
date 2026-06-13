val enqueue_list_in_queue : 'a Queue.t -> 'a list -> unit
val dequeue_list_from_queue : 'a Queue.t -> int -> 'a list option
val equals : ('a -> 'a -> bool) -> 'a Queue.t -> 'a Queue.t -> bool
val to_string : ('a -> string) -> 'a Queue.t -> string
val of_string : (string -> 'a) -> string -> 'a Queue.t
