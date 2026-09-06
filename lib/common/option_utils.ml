let unwrap_or_else f o = match o with Some x -> x | None -> f ()
let unwrap_or_raise e o = o |> unwrap_or_else (fun () -> raise e)
let unwrap_or x o = match o with Some v -> v | None -> x
let unwrap_or_crash s o = match o with Some v -> v | None -> failwith s
let or_else f = function Some x -> Some x | None -> f ()

let flatten l =
  List.fold_left
    (fun acc elt ->
      match (acc, elt) with
      | None, _ | _, None -> None
      | Some acc, Some elt -> Some (elt :: acc))
    (Some []) l
