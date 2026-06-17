exception EntryQueueEmpty
exception NotEnoughElementInEntryQueue

type 'v apply = (string, 'v) Hashtbl.t -> 'v Queue.t -> 'v Queue.t -> unit
type ('v, 'b) production = { behavior : 'b; output : 'v Queue.t }
type ('v, 'b) t = { entry : 'v Queue.t; prod : ('v, 'b) production Queue.t }

let get_output_queue k =
  Queue.peek_opt k.prod
  |> Option.map (fun p -> p.output)
  |> Option_utils.unwrap_or k.entry

let enqueue k x = Queue.add x k.entry
let dequeue k = get_output_queue k |> Queue.take_opt

let dequeue_entry k =
  match Queue.take_opt k.entry with
  | Some x -> x
  | None -> raise EntryQueueEmpty

let create () = { entry = Queue.create (); prod = Queue.create () }

let enqueue_behavior k behavior =
  Queue.add { behavior; output = Queue.create () } k.prod

let dequeue_behavior k = Queue.take_opt k.prod

let of_list lst =
  let k = create () in
  List.iter (enqueue k) lst;
  k

let produce k process get_args =
  let rec work source prods =
    match prods with
    | [] -> ()
    | p :: rest ->
        let args = get_args p.behavior in
        let values =
          Queue_utils.dequeue_list_from_queue source (List.length args)
          |> Option_utils.unwrap_or_raise NotEnoughElementInEntryQueue
        in
        let args = List.combine args values |> List.to_seq |> Hashtbl.of_seq in
        process p.behavior args source p.output;
        work p.output rest
  in
  let prods = k.prod |> Queue.to_seq |> List.of_seq |> List.rev in
  match prods with [] -> () | _ -> work k.entry prods

let output_length k = get_output_queue k |> Queue.length
let entry_length k = Queue.length k.entry

(*does not take in account the behaviors ast*)
let equal eq k1 k2 =
  Queue_utils.equals eq k1.entry k2.entry
  && Queue.length k1.prod = Queue.length k2.prod
  &&
  let to_list k = k |> Queue.to_seq |> List.of_seq in
  List.combine (to_list k1.prod) (to_list k2.prod)
  |> List.for_all (fun (p1, p2) -> Queue_utils.equals eq p1.output p2.output)

let entry_is_empty k = Queue.is_empty k.entry
let output_is_empty k = get_output_queue k |> Queue.is_empty
let is_empty k = output_is_empty k && entry_is_empty k

let to_string to_string k =
  Queue.to_seq k.prod |> List.of_seq
  |> List.map (fun p ->
      Printf.sprintf "|%s" @@ Queue_utils.to_string to_string p.output)
  |> String.concat ""
  |> Printf.sprintf "%s%s" (Queue_utils.to_string to_string k.entry)

let of_string default_behavior of_string s =
  match String.split_on_char '|' s with
  | [ _ ] ->
      { entry = Queue_utils.of_string of_string s; prod = Queue.create () }
  | entry :: prods ->
      {
        entry = Queue_utils.of_string of_string entry;
        prod =
          List.map
            (fun p ->
              {
                behavior = default_behavior;
                output = Queue_utils.of_string of_string p;
              })
            prods
          |> List.to_seq |> Queue.of_seq;
      }
  | _ -> invalid_arg "Invalid string format for a kyu."
