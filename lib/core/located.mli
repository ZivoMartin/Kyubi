type 'a t = { span : Span.t; value : 'a }

val create : Position.t -> Position.t -> 'a -> 'a t
