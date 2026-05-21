open Queue
open Builtin
open Option_utils
open Value

exception Queue_not_found of string
exception Empty_queue of string
exception Invalid_env_format
exception QueueHasNoBehavior of string

let env_base_cap = 1000

type env = { queues : (string, Value.t Queue.t) Hashtbl.t }

let insert_builtins e =
  List.iter
    (fun name -> Hashtbl.replace e.queues name (Queue.create ()))
    (Builtin.get_all_string ())

let create (_ : unit) : env =
  let e = { queues = Hashtbl.create env_base_cap } in
  insert_builtins e;
  e

let equal e1 e2 =
  let queue_equal q1 q2 =
    Queue.to_seq q1 |> List.of_seq = (Queue.to_seq q2 |> List.of_seq)
  in
  let check e1 e2 =
    Hashtbl.to_seq e1.queues
    |> Seq.for_all (fun (name, q1) ->
        match Hashtbl.find_opt e2.queues name with
        | Some q2 -> queue_equal q1 q2
        | None -> Queue.is_empty q1)
  in
  check e1 e2 && check e2 e1

let string_of_env (e : env) =
  Hashtbl.to_seq e.queues
  |> Seq.filter_map (fun (name, q) ->
      let contents =
        Queue.to_seq q |> Seq.map Value.to_string |> List.of_seq
        |> String.concat " "
      in
      if String.empty = contents then None
      else Some (Printf.sprintf "%s: %s" name contents))
  |> List.of_seq |> String.concat "\n"

let env_of_string (s : string) : env =
  let queue_of_list lst =
    let q = Queue.create () in
    List.iter (Fun.flip Queue.add q) lst;
    q
  in
  let hashtable_of_list lst =
    let h = Hashtbl.create env_base_cap in
    List.iter (fun (k, v) -> Hashtbl.replace h k v) lst;
    h
  in

  let parse_queue line =
    String.split_on_char ' ' line
    |> List.filter_map (fun v ->
        let v = String.trim v in
        if v = String.empty then None else Some (Value.of_string v))
    |> queue_of_list
  in
  let queues =
    String.split_on_char '\n' s
    |> List.filter_map (fun line ->
        let line = String.trim line in
        if line = String.empty then None
        else
          match String.split_on_char ':' line with
          | [ name; queue ] -> Some (name, parse_queue queue)
          | _ -> raise Invalid_env_format)
  in

  { queues = hashtable_of_list queues }

let enqueue e name v : unit =
  let queue =
    Hashtbl.find_opt e.queues name
    |> Option_utils.unwrap_or_else (fun () ->
        let queue = Queue.create () in
        Hashtbl.add e.queues name queue;
        queue)
  in
  Queue.add v queue

(* private *)
let fetch_queue e q =
  Hashtbl.find_opt e.queues q
  |> Option_utils.unwrap_or_raise @@ Queue_not_found q

let dequeue e q_name =
  fetch_queue e q_name |> Queue.take_opt
  |> unwrap_or_raise @@ Empty_queue q_name

let dequeue_in (e : env) (q1_name : string) (q2_name : string) : unit =
  dequeue e q1_name |> enqueue e q2_name

let dequeue_n e name n =
  List.init n (fun i -> i)
  |> List.fold_left (fun acc _ -> dequeue e name :: acc) []
  |> List.rev (* We want the result to be in the good fifo order *)

let dequeue_all_in e q1 q2 =
  for i = 0 to Queue.length (fetch_queue e q1) - 1 do
    dequeue_in e q1 q2
  done

let produce_in e q1 q2 =
  let b =
    Builtin.from_string_opt q1
    |> Option_utils.unwrap_or_raise @@ QueueHasNoBehavior q1
  in
  Builtin.number_of_arg b |> dequeue_n e q1 |> Builtin.process b |> enqueue e q2

let process_n_in f e n q1 q2 =
  if n = 0 then ()
  else
    for i = 0 to n - 1 do
      f e q1 q2
    done

let dequeue_n_in = process_n_in dequeue_in
let produce_n_in = process_n_in produce_in
