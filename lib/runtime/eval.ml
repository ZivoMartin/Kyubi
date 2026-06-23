let rec compile_into_executable e v =
  match v with
  | Value.Behavior (args, ast) ->
      Behavior.Defined
        ( args,
          ast,
          fun args input output ->
            let e = Env.set_input_output e input output in
            let _ = eval e ast args in
            () )
  | _ -> failwith "Only accept Behavior value"

and reverse_into_value b =
  match b with
  | Behavior.Defined (args, ast, _) -> Value.Behavior (args, ast)
  | Behavior.Builtin (b, f) -> Value.BuiltinBehavior (b, f)

and step e tree args_map =
  match tree with
  | Ast.Branching _ | Ast.Empty | Ast.Behavior _ | Ast.Kyu _ | Ast.Literal _
  | Ast.Flow (_, []) ->
      None
  | Ast.Program (instr, rest) -> (
      match (step e instr args_map, rest) with
      | Some new_instr, _ -> Some (Ast.Program (new_instr, rest))
      | None, rest -> step e rest args_map)
  | Ast.Flow (left, (op, right) :: rest) -> (
      let return k rest = Some (Ast.Flow (Ast.Kyu k, rest)) in
      match (left, op, right) with
      | Ast.Literal l, Operator.Enqueue _, Ast.Kyu k ->
          let v = Value.of_literal (Some args_map) l in
          Env.enqueue e k v;
          return k rest
      | Ast.Behavior (args, body), Operator.Enqueue _, Ast.Kyu k ->
          let v = Value.Behavior (args, body) in
          Env.enqueue e k v;
          return k rest
      | Ast.Kyu k1, Operator.Enqueue f, Ast.Kyu k2 ->
          Env.dequeue_in e k1 k2 f;
          return k2 rest
      | Ast.Kyu (Kyu_id.Name k1), Operator.Produce (f1, f2), Ast.Kyu k2 ->
          Env.produce_in e k1 k2 f1 f2;
          return k2 rest
      | Ast.Kyu k1, Operator.Promote f, Ast.Kyu (Kyu_id.Name k2 as k2_id) ->
          Env.promote_in e (compile_into_executable e) k1 k2 f;
          return k2_id rest
      | Ast.Kyu (Kyu_id.Name k1), Operator.Demote f, Ast.Kyu k2 ->
          Env.demote_in e reverse_into_value k1 k2 f;
          return k2 rest
      | ( Ast.Kyu (Kyu_id.Name k1),
          Operator.Benqueue f,
          Ast.Kyu (Kyu_id.Name k2 as k2_id) ) ->
          Env.dequeue_behavior_in e k1 k2 f;
          return k2_id rest
      | ( Ast.Behavior (args, b),
          Operator.Benqueue Flow_size.Absent,
          Ast.Kyu (Kyu_id.Name k2 as k2_id) ) ->
          let b = compile_into_executable e (Value.Behavior (args, b)) in
          Env.enqueue_behavior e k2 b;
          return k2_id rest
      | Ast.Kyu k1, Operator.Dup f, Ast.Kyu k2 ->
          Env.dup_in e k1 k2 f;
          return k2 rest
      | _, _, Ast.Branching _ -> failwith "todo"
      | Ast.Branching _, _, _ ->
          failwith "You cannot start the flow with a branching"
      | _, Operator.Enqueue _, _
      | _, Operator.Dup _, _
      | _, Operator.Produce _, _
      | _, Operator.Promote _, _
      | _, Operator.Demote _, _
      | _, Operator.Benqueue _, _ ->
          failwith "type error")

and eval e tree args_map =
  let rec work tree =
    match step e tree args_map with
    | Some new_tree -> work new_tree
    | None -> tree
  in
  work tree

let eval tree =
  let e = Env.create () in
  (eval e tree (Hashtbl.create 1), e)
