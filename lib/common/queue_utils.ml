let enqueue_list_in_queue q l = List.iter (fun x -> Queue.add x q) l

let dequeue_list_from_queue q n =
  let rec work acc n =
    if n = 0 then Some acc
    else Option.bind (Queue.take_opt q) @@ fun x -> work (x :: acc) (n - 1)
  in
  if Queue.length q < n then None else work [] n |> Option.map List.rev

let equals eq q1 q2 =
  Queue.length q1 = Queue.length q2
  &&
  let l1 = Queue.to_seq q1 |> List.of_seq in
  let l2 = Queue.to_seq q2 |> List.of_seq in
  List.for_all2 eq l1 l2

let to_string cast q =
  Queue.to_seq q |> Seq.map cast |> List.of_seq |> String.concat " "

let of_string cast s =
  String.split_on_char ' ' s |> List.map String.trim
  |> List.filter_map (fun s -> if s = String.empty then None else Some (cast s))
  |> List.to_seq |> Queue.of_seq
