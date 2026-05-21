type operator =
  | Enqueue
  | Produce
  | ProduceN of int
  | EnqueueN of int
  | EnqueueAll

let string_of_operator = function
  | Enqueue -> "->"
  | EnqueueAll -> "_>"
  | Produce -> "-->"
  | EnqueueN n -> Printf.sprintf "-%d>" n
  | ProduceN n -> Printf.sprintf "--%d>" n

let operator_of_string = function
  | "->" -> Enqueue
  | "-->" -> Produce
  | "_>" -> EnqueueAll
  | s -> (
      let parsers =
        [
          (fun s -> Scanf.sscanf_opt s "-%d>" (fun n -> EnqueueN n));
          (fun s -> Scanf.sscanf_opt s "--%d>" (fun n -> ProduceN n));
        ]
      in
      match List.find_map (fun parse -> parse s) parsers with
      | Some op -> op
      | None ->
          invalid_arg
            (Printf.sprintf "operator_of_string: invalid operator %S" s))

let all () = [ Enqueue; Produce; EnqueueAll; EnqueueN 2 ]
let all_string () = all () |> List.map string_of_operator
