val unwrap_or_else : (unit -> 'a) -> 'a option -> 'a
val unwrap_or_raise : exn -> 'a option -> 'a
val unwrap_or : 'a -> 'a option -> 'a
val flatten : 'a option list -> 'a list option
