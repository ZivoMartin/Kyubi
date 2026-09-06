type stepres = Final of Ast.t | Incomplete of Ast.t

let ensure_no_flow = function
  | Flow_size.Absent | Flow_size.Const 1 -> ()
  | _ -> failwith "You cannot specify the flow in this context."

let rec compile_into_executable e v =
  match v with
  | Value.Behavior (args, ast) ->
      Behavior.Defined
        ( args,
          ast,
          fun args input output ->
            let e = Env.set_input_output e input output in
            let bindings = Bindings.create () in
            Bindings.set_args bindings args;
            let _ = eval e ast bindings in
            () )
  | _ -> failwith "Only accept Behavior value"

and reverse_into_value b =
  match b with
  | Behavior.Defined (args, ast, _) -> Value.Behavior (args, ast)
  | Behavior.Builtin (b, f) -> Value.BuiltinBehavior (b, f)

and feed_branching e v branches bindings rest =
  let build flows = Ast.Flow (Ast.of_list Fun.id flows, rest) in
  match List.find_opt (fun (p, _) -> Value.matches p v) branches with
  | Some (Pattern.RuntimeVal name, flows) ->
      Bindings.add_pat_binding bindings name v;
      build flows
  | Some (_, flows) -> build flows
  | None -> failwith "Failed to match."

and step e tree bindings =
  match tree with
  | Ast.Branching _ | Ast.Empty | Ast.Behavior _ | Ast.Kyu _ | Ast.Literal _ ->
      Final tree
  | Ast.Flow (left, []) -> step e left bindings
  | Ast.Program (instr, rest) -> (
      match (step e instr bindings, rest) with
      | Incomplete new_instr, _ -> Incomplete (Ast.Program (new_instr, rest))
      | Final res, Ast.Empty -> Final res
      | _, _ -> step e rest bindings)
  | Ast.Flow (left, ((op, right) :: rest as stream)) -> (
      match step e left bindings with
      | Incomplete new_left -> Incomplete (Ast.Flow (new_left, stream))
      | Final left -> (
          let return k rest = Incomplete (Ast.Flow (Ast.Kyu k, rest)) in
          match (left, op, right) with
          | Ast.Literal l, Operator.Enqueue _, Ast.Kyu k ->
              let v = Value.of_literal (Some bindings) l in
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
          | Ast.Literal l, Operator.Enqueue f, Ast.Branching branches ->
              ensure_no_flow f;
              let v = Value.of_literal (Some bindings) l in
              Incomplete (feed_branching e v branches bindings rest)
          | Ast.Kyu k, Operator.Enqueue f, Ast.Branching branches ->
              ensure_no_flow f;
              let v = Env.dequeue e k in
              Incomplete (feed_branching e v branches bindings rest)
          | Ast.Kyu k, Operator.Dup f, Ast.Branching branches ->
              ensure_no_flow f;
              let v = Env.peek e k in
              Incomplete (feed_branching e v branches bindings rest)
          | ( Ast.Kyu (Kyu_id.Name k1 as k1id),
              Operator.Produce (f1, f2),
              Ast.Branching branches ) ->
              ensure_no_flow f2;
              (* Small trick here: we produce [f1] times while dequeuing zero values from [k1]. This fills the output queue, whose values can then be dequeued by the branches. *)
              Env.produce_in e k1 k1id f1 (Flow_size.Const 0);
              let v = Env.dequeue e k1id in
              Incomplete (feed_branching e v branches bindings rest)
          | Ast.Branching _, _, _ ->
              failwith "You cannot start the flow with a branching"
          | _, Operator.Enqueue _, _
          | _, Operator.Dup _, _
          | _, Operator.Produce _, _
          | _, Operator.Promote _, _
          | _, Operator.Demote _, _
          | _, Operator.Benqueue _, _ ->
              failwith
              @@ Printf.sprintf "\n type error\n left: %s mid: %s\n right: %s"
                   (Ast.to_string left) (Operator.to_string op)
                   (Ast.to_string right)))

and eval e tree bindings =
  let rec work tree =
    match step e tree bindings with
    | Incomplete new_tree -> work new_tree
    | Final tree -> tree
  in
  work tree

let eval tree =
  let e = Env.create () in
  (eval e tree (Bindings.create ()), e)
