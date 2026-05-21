let unwrap_or_else f o = match o with Some x -> x | None -> f ()
let unwrap_or_raise e o = o |> unwrap_or_else (fun () -> raise e)
