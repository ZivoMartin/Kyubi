type 'a t = { span : Span.t; value : 'a }

let create p1 p2 value = { span = Span.create p1 p2; value }
