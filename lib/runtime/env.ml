exception Empty_kyu of string
exception Empty_behavior_kyu of string
exception Invalid_env_format

let env_base_cap = 1000

type t = { kyus : (string, (Value.t, Value.t Behavior.t) Kyu.t) Hashtbl.t }

let generic_insert_builtin e insert =
  List.iter
    (fun name ->
      let kyu = Kyu.create () in
      let b : Value.t Behavior.t =
        name |> Builtin.from_string |> Value.activate_builtin
      in
      Kyu.enqueue_behavior kyu b;
      insert e.kyus name kyu)
    (Builtin.get_all_string ())

let insert_missing_builtins e =
  generic_insert_builtin e (fun kyus name kyu ->
      if Hashtbl.mem e.kyus name then () else Hashtbl.replace e.kyus name kyu)

let insert_builtins e =
  generic_insert_builtin e (fun kyus name kyu ->
      Hashtbl.replace e.kyus name kyu)

let create (_ : unit) =
  let e = { kyus = Hashtbl.create env_base_cap } in
  insert_builtins e;
  e

let equal e1 e2 =
  let check e1 e2 =
    Hashtbl.to_seq e1.kyus
    |> Seq.for_all (fun (name, k1) ->
        match Hashtbl.find_opt e2.kyus name with
        | Some k2 -> Kyu.equal Value.equal k1 k2
        | None -> Kyu.is_empty k1)
  in
  check e1 e2 && check e2 e1

let string_of_env e =
  Hashtbl.to_seq e.kyus
  |> Seq.map (fun (name, k) ->
      let contents = Kyu.to_string Value.to_string k in
      Printf.sprintf "%s: %s" name contents)
  |> List.of_seq |> String.concat "\n"

let env_of_string s =
  let hashtable_of_list lst =
    let h = Hashtbl.create env_base_cap in
    List.iter (fun (k, v) -> Hashtbl.replace h k v) lst;
    h
  in

  let kyus =
    String.split_on_char '\n' s
    |> List.filter_map (fun line ->
        let line = String.trim line in
        if line = String.empty then None
        else
          match String.split_on_char ':' line with
          | [ name; kyu ] ->
              Some
                ( name,
                  Kyu.of_string Behavior.default_behavior Value.of_string kyu )
          | _ -> raise Invalid_env_format)
  in

  let env = { kyus = hashtable_of_list kyus } in
  insert_missing_builtins env;
  env

(* private *)
let fetch_kyu e kyu_name =
  Hashtbl.find_opt e.kyus kyu_name
  |> Option_utils.unwrap_or_else (fun _ ->
      let kyu = Kyu.create () in
      Hashtbl.add e.kyus kyu_name kyu;
      kyu)

let enqueue e name v =
  let kyu = fetch_kyu e name in
  Kyu.enqueue kyu v

let dequeue e kyu_name =
  fetch_kyu e kyu_name |> Kyu.dequeue
  |> Option_utils.unwrap_or_raise @@ Empty_kyu kyu_name

let dequeue_in_once e dequeue enqueue src dest = dequeue e src |> enqueue e dest

let dequeue_n e dequeue src n =
  List.init n (fun i -> i)
  |> List.fold_left (fun acc _ -> dequeue e src :: acc) []
  |> List.rev (* We want the result to be in the good fifo order *)

let dequeue_all_in e dequeue enqueue src dest =
  for i = 0 to Kyu.output_length (fetch_kyu e src) - 1 do
    dequeue_in_once e dequeue enqueue src dest
  done

let dequeue_n_in e n dequeue enqueue src dest =
  for i = 0 to n - 1 do
    dequeue_in_once e dequeue enqueue src dest
  done

let produce_once e k1_name =
  let k1 = fetch_kyu e k1_name in
  let _ = Kyu.produce k1 Behavior.process Behavior.get_args in
  ()

let rec produce_all e k =
  try
    (* if we cannot produce this will fail *)
    produce_once e k;
    produce_all e k
  with Kyu.NotEnoughElementInEntryQueue -> ()

let produce_n e n k =
  for i = 0 to n - 1 do
    produce_once e k
  done

let generic_dequeue_in e dequeue enqueue src dest = function
  | Flow_size.Absent -> dequeue_in_once e dequeue enqueue src dest
  | Flow_size.Const n -> dequeue_n_in e n dequeue enqueue src dest
  | Flow_size.All -> dequeue_all_in e dequeue enqueue src dest

let generic_produce_in e dequeue enqueue src dest f1 f2 =
  (match f1 with
  | Flow_size.Absent -> produce_once e src
  | Flow_size.Const n -> produce_n e n src
  | Flow_size.All -> produce_all e src);
  generic_dequeue_in e dequeue enqueue src dest f2

let dequeue_in e = generic_dequeue_in e dequeue enqueue

let dequeue_in_this_queue e k q =
  generic_dequeue_in e dequeue (fun _ x q -> Queue.add q x) k q

let produce_in e = generic_produce_in e dequeue enqueue

let produce_in_this_queue e k q =
  generic_produce_in e dequeue (fun _ x q -> Queue.add q x) k q

let enqueue_behavior e k b =
  let kyu = fetch_kyu e k in
  Kyu.enqueue_behavior kyu b

let dequeue_behavior e k =
  let kyu = fetch_kyu e k in
  Kyu.dequeue_behavior kyu
  |> Option_utils.unwrap_or_raise @@ Empty_behavior_kyu k

let dequeue_behavior_in e =
  generic_dequeue_in e dequeue_behavior (fun e k p ->
      enqueue_behavior e k p.behavior)

let promote_in e compile =
  generic_dequeue_in e dequeue (fun e k v ->
      let behavior = compile v in
      enqueue_behavior e k behavior)
