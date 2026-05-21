type operator =
  | Enqueue
  | Produce
  | ProduceN of int
  | EnqueueN of int
  | EnqueueAll

val string_of_operator : operator -> string
val operator_of_string : string -> operator
val all : unit -> operator list
val all_string : unit -> string list
