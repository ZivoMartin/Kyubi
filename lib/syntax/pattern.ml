type t = Number of int | Unit

let to_string = function Number x -> string_of_int x | Unit -> "()"
