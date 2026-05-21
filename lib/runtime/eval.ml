open Token
open Ast
open Env
open Builtin

exception TypeError

let rec step (e : env) (tree : ast) : ast option =
  match tree with
  | Ast.Ident _ | Ast.Value _ | Ast.Flow (_, []) -> None
  | Ast.Program (instr, rest) -> (
      match (step e instr, rest) with
      | Some new_instr, _ -> Some (Ast.Program (new_instr, rest))
      | None, Some rest -> step e rest
      | None, None -> None)
  | Ast.Flow (left, (op, right) :: rest) -> (
      let return name rest = Some (Ast.Flow (Ast.Ident name, rest)) in
      match (left, op, right) with
      | Ast.Value v, Operator.Enqueue, Ast.Ident name ->
          Env.enqueue e name v;
          return name rest
      | Ast.Ident q1, Operator.Enqueue, Ast.Ident q2 ->
          Env.dequeue_in e q1 q2;
          return q2 rest
      | Ast.Ident q1, Operator.Produce, Ast.Ident q2 ->
          Env.produce_in e q1 q2;
          return q2 rest
      | Ast.Ident q1, Operator.EnqueueAll, Ast.Ident q2 ->
          Env.dequeue_all_in e q1 q2;
          return q2 rest
      | Ast.Ident q1, Operator.EnqueueN n, Ast.Ident q2 ->
          Env.dequeue_n_in e n q1 q2;
          return q2 rest
      | Ast.Ident q1, Operator.ProduceN n, Ast.Ident q2 ->
          Env.produce_n_in e n q1 q2;
          return q2 rest
      | _, Operator.Enqueue, _
      | _, Operator.Produce, _
      | _, Operator.EnqueueAll, _
      | _, Operator.ProduceN _, _
      | _, Operator.EnqueueN _, _ ->
          raise TypeError)

let eval (tree : ast) : ast * env =
  let rec work (e : env) (tree : ast) : ast =
    match step e tree with Some new_tree -> work e new_tree | None -> tree
  in
  let e = Env.create () in
  (work e tree, e)
