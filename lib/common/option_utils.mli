val unwrap_or_else : (unit -> 'a) -> 'a option -> 'a
val unwrap_or_raise : exn -> 'a option -> 'a
val unwrap_or_crash : string -> 'a option -> 'a
val unwrap_or : 'a -> 'a option -> 'a
val or_else : (unit -> 'a option) -> 'a option -> 'a option
val flatten : 'a option list -> 'a list option
