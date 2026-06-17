let rec compile_into_executable e v =
  match v with
  | Value.Behavior (args, ast) ->
      Behavior.Defined
        ( args,
          ast,
          fun args input output ->
            let _ = eval e ast args input output in
            () )
  | _ -> failwith "Only accept Behavior value"

and reverse_into_value e b =
  match b with
  | Behavior.Defined (args, ast, _) -> Value.Behavior (args, ast)
  | Behavior.Builtin (b, f) -> Value.BuiltinBehavior (b, f)

and step e tree args_map input_queue output_queue =
  match tree with
  | Ast.Empty | Ast.Behavior _ | Ast.SQueue _ | Ast.Ident _ | Ast.Literal _
  | Ast.Flow (_, []) ->
      None
  | Ast.Program (instr, rest) -> (
      match (step e instr args_map input_queue output_queue, rest) with
      | Some new_instr, _ -> Some (Ast.Program (new_instr, rest))
      | None, rest -> step e rest args_map input_queue output_queue)
  | Ast.Flow (left, (op, right) :: rest) -> (
      let return name rest = Some (Ast.Flow (Ast.Ident name, rest)) in
      match (left, op, right) with
      | Ast.Literal l, Operator.Enqueue _, Ast.Ident name ->
          let v = Value.of_literal (Some args_map) l in
          Env.enqueue e name v;
          return name rest
      | Ast.Behavior (args, body), Operator.Enqueue _, Ast.Ident name ->
          let v = Value.Behavior (args, body) in
          Env.enqueue e name v;
          return name rest
      | Ast.Ident q1, Operator.Enqueue f, Ast.Ident q2 ->
          Env.dequeue_in e q1 q2 f;
          return q2 rest
      | Ast.Ident q1, Operator.Produce (f1, f2), Ast.Ident q2 ->
          Env.produce_in e q1 q2 f1 f2;
          return q2 rest
      | Ast.Ident q1, Operator.Promote f, Ast.Ident q2 ->
          Env.promote_in e (compile_into_executable e) q1 q2 f;
          return q2 rest
      | Ast.Ident q1, Operator.Demote f, Ast.Ident q2 ->
          Env.demote_in e (reverse_into_value e) q1 q2 f;
          return q2 rest
      | Ast.Ident q1, Operator.Benqueue f, Ast.Ident q2 ->
          Env.dequeue_behavior_in e q1 q2 f;
          return q2 rest
      | Ast.Behavior (args, b), Operator.Benqueue _, Ast.Ident q2 ->
          let b = compile_into_executable e (Value.Behavior (args, b)) in
          Env.enqueue_behavior e q2 b;
          return q2 rest
      | Ast.SQueue Special_queue.Input, Operator.Enqueue _, Ast.Ident name ->
          let v = Queue.take input_queue in
          Env.enqueue e name v;
          return name rest
      | Ast.Ident name, Operator.Enqueue f, Ast.SQueue Special_queue.Output ->
          failwith "todo"
      | ( Ast.SQueue Special_queue.Input,
          Operator.Enqueue f,
          Ast.SQueue Special_queue.Output ) ->
          failwith "todo"
      | Ast.Literal l, Operator.Enqueue _, Ast.SQueue Special_queue.Output ->
          let v = Value.of_literal (Some args_map) l in
          Queue.add v output_queue;
          None
      | ( Ast.Behavior (args, body),
          Operator.Enqueue f,
          Ast.SQueue Special_queue.Output ) ->
          failwith "todo: enqueue"
      | Ast.Ident q1, Operator.Produce (f1, f2), Ast.SQueue Special_queue.Output
        ->
          Env.produce_in_this_queue e q1 output_queue f1 f2;
          None
      | _, Operator.Enqueue _, _
      | _, Operator.Produce _, _
      | _, Operator.Promote _, _
      | _, Operator.Demote _, _
      | _, Operator.Benqueue _, _ ->
          failwith "type error")

and eval e tree args_map input_queue output_queue =
  let rec work tree =
    match step e tree args_map input_queue output_queue with
    | Some new_tree -> work new_tree
    | None -> tree
  in
  work tree

let eval tree =
  let e = Env.create () in
  (eval e tree (Hashtbl.create 1) (Queue.create ()) (Queue.create ()), e)
