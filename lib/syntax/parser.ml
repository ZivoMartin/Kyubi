open Located

let throw e = raise @@ Parse_error.Parsing_error e
let unexpected found expected = throw @@ UnexpectedToken { found; expected }

let parse tokens =
  let parse_special_queue token in_behavior =
    let squeue = Special_queue.of_token token.value in
    if in_behavior then Ast.SQueue squeue
    else throw @@ SpecialQueueOutOfBehavior token
  in

  let rec parse_one_flow first acc tokens in_behavior =
    let return () =
      let flow = List.rev acc in
      (Ast.Flow (first, flow), tokens)
    in
    match tokens with
    | { value = Token.Operator op } :: right :: rest ->
        let right_ast =
          match right.value with
          | Token.Ident name -> Ast.Ident name
          | Token.Dollar -> throw @@ CannotEnqueueInput right
          | Token.At -> parse_special_queue right in_behavior
          | _ -> throw @@ unexpected right [ FlowComponent ]
        in

        (match acc with
        | (_, Ast.SQueue Special_queue.Output) :: _ ->
            throw @@ CannotDequeueOutput right
        | _ -> ());

        parse_one_flow first ((op, right_ast) :: acc) rest in_behavior
    | _ -> return ()
  in

  let rec get_first_node first_token tokens in_behavior =
    match first_token.value with
    | Token.Ident name -> Some (Ast.Ident name, tokens)
    | Token.Unit -> Some (Ast.Literal Literal.Unit, tokens)
    | Token.Number n -> Some (Ast.Literal (Literal.Number n), tokens)
    | Token.Arg name -> Some (Ast.Literal (Literal.Arg name), tokens)
    | Token.At -> throw @@ CannotDequeueOutput first_token
    | Token.Dollar -> Some (parse_special_queue first_token in_behavior, tokens)
    | Token.ClosingBracket when in_behavior -> None
    | _ -> (
        match parse_behavior (first_token :: tokens) with
        | Some b -> Some b
        | _ -> unexpected first_token [ FlowStart ])
  and parse_program tokens in_behavior =
    match tokens with
    | [] -> (Ast.Empty, [])
    | first :: tokens -> (
        match get_first_node first tokens in_behavior with
        | Some (first, tokens) ->
            let tree, rest = parse_one_flow first [] tokens in_behavior in
            let next, rest = parse_program rest in_behavior in
            (Ast.Program (tree, next), rest)
        | None -> (Ast.Empty, tokens))
  and parse_behavior tokens =
    let rec parse_args opening tokens acc =
      match tokens with
      | { value = Token.Colon } :: tokens -> (tokens, List.rev acc)
      | { value = Token.Arg a } :: tokens -> parse_args opening tokens (a :: acc)
      | [] -> throw @@ UnclosedBehavior opening.span
      | guilty_token :: _ when acc <> [] ->
          unexpected guilty_token [ BehaviorColon ]
      | _ -> (tokens, List.rev acc)
    in

    match tokens with
    | ({ value = Token.OpeningBracket } as opening) :: tokens ->
        let tokens, args = parse_args opening tokens [] in
        let body, rest = parse_program tokens true in
        Some (Ast.Behavior (args, body), rest)
    | _ -> None
  in

  let ast, rest = parse_program tokens false in
  match rest with [] -> ast | token :: _ -> unexpected token []
