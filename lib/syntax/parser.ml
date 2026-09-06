open Located

let throw e = raise @@ Parse_error.Parsing_error e
let unexpected found expected = throw @@ UnexpectedToken { found; expected }

let parse tokens =
  let parse_special_queue token in_behavior =
    let squeue = Kyu_id.of_token token.value in
    if in_behavior then Ast.Kyu squeue
    else throw @@ SpecialQueueOutOfBehavior token
  in

  let rec build_prog_from_flows : Ast.t list -> Ast.t = function
    | [] -> Ast.Empty
    | f :: others -> Ast.Program (f, build_prog_from_flows others)
  in
  let rec parse_pattern span = function
    | { value = Token.Number n } :: rest -> (Pattern.Number n, rest)
    | { value = Token.RuntimeVal name } :: rest ->
        (Pattern.RuntimeVal name, rest)
    | { value = Token.OpeningPar } :: { value = Token.ClosingPar } :: rest ->
        (Pattern.Unit, rest)
    | _ -> throw @@ Parse_error.InvalidFlowInBranch span
  and parse_branching in_behavior rest location =
    let rec work acc = function
      | { value = Token.Bar } :: { value = Token.Gt } :: rest ->
          (Ast.Branching (List.rev acc), rest)
      | { value = Token.Bar; span } :: rest -> (
          let pat, rest = parse_pattern span rest in
          match parse_flows rest in_behavior with
          | Some ([], _) | None -> throw @@ Parse_error.InvalidFlowInBranch span
          | Some (flows, rest) -> work ((pat, flows) :: acc) rest)
      | guilty_token :: _ ->
          unexpected guilty_token [ BranchingCloser; BranchingBar ]
      | [] -> throw @@ Parse_error.UnclosedBranching location
    in

    work [] rest
  and parse_one_flow first tokens in_behavior :
      Ast.t * Token.t Located.t list * (Operator.t * Ast.t) option =
    let rec work first acc tokens =
      let return () =
        let flow = List.rev acc in
        let h = match flow with h :: _ -> Some h | _ -> None in
        (Ast.Flow (first, flow), tokens, h)
      in
      match tokens with
      | { value = Token.Operator op; _ } :: right :: rest ->
          let right_ast, rest =
            match right.value with
            | Token.Bar ->
                parse_branching in_behavior (right :: rest) right.span
            | Token.Ident name -> (Ast.Kyu (Kyu_id.Name name), rest)
            | Token.Dollar -> throw @@ CannotEnqueueInput right
            | Token.At -> (parse_special_queue right in_behavior, rest)
            | _ -> throw @@ unexpected right [ FlowComponent ]
          in

          (match acc with
          | (_, Ast.Kyu Kyu_id.Output) :: _ ->
              throw @@ CannotDequeueOutput right
          | _ -> ());

          work first ((op, right_ast) :: acc) rest
      | _ -> return ()
    in
    work first [] tokens
  and parse_flows tokens in_behavior :
      (Ast.t list * Token.t Located.t list) option =
    parse_first_node tokens in_behavior
    |> Option.map (fun (firsts, tokens) ->
        let rec work firsts =
          match firsts with
          | [ first ] ->
              let flow, rest, right = parse_one_flow first tokens in_behavior in
              let right =
                right
                |> Option.map (fun r -> [ r ])
                |> Option_utils.unwrap_or []
              in
              ([ flow ], rest, right)
          | first :: others ->
              let flows, rest, right = work others in
              let tree = Ast.Flow (first, right) in
              (tree :: flows, rest, right)
          | [] -> ([], tokens, [])
        in
        let flows, rest, _ = work firsts in
        (flows, rest))
  and parse_value = function
    | { value = Token.OpeningPar } :: { value = Token.ClosingPar } :: rest ->
        Some (Ast.Literal Literal.Unit, rest)
    | { value = Token.Number n } :: rest ->
        Some (Ast.Literal (Literal.Number n), rest)
    | { value = Token.RuntimeVal name } :: rest ->
        Some (Ast.Literal (Literal.RuntimeVal name), rest)
    | { value = Token.OpeningBracket } :: rest as tokens ->
        parse_behavior tokens
    | _ -> None
  and parse_serie = function
    | ({ value = Token.OpeningSBracket } as opening) :: tokens ->
        let rec work first =
          let parse_and_ret tokens =
            match parse_value tokens with
            | Some (v, rest) ->
                work false rest
                |> Option.map (fun (vals, rest) -> (v :: vals, rest))
            | None -> unexpected (List.hd tokens) [ FlowStart ]
          in
          function
          | [] -> throw @@ UnclosedSerie opening.span
          | { value = Token.ClosingSBracket } :: rest -> Some ([], rest)
          | { value = Token.Comma } :: tokens -> parse_and_ret tokens
          | tokens when first -> parse_and_ret tokens
          | guilty_token :: v ->
              unexpected guilty_token [ ClosingBracket; SerieComma ]
        in
        work true tokens
    | _ -> None
  and parse_first_node tokens in_behavior =
    let ret ast = Some ([ ast ], List.tl tokens) in
    match tokens with
    | { value = Token.Ident name } :: rest -> ret @@ Ast.Kyu (Kyu_id.Name name)
    | ({ value = Token.At } as first) :: rest ->
        throw @@ CannotDequeueOutput first
    | ({ value = Token.Dollar } as first) :: rest ->
        ret @@ parse_special_queue first in_behavior
    | { value = Token.OpeningSBracket } :: rest -> parse_serie tokens
    | [] -> None
    | _ -> parse_value tokens |> Option.map (fun (ast, rest) -> ([ ast ], rest))
  and parse_program tokens in_behavior =
    match parse_flows tokens in_behavior with
    | Some (flows, rest) -> (
        let p = build_prog_from_flows flows in
        match rest with
        | [] | { value = Token.ClosingBracket } :: _ -> (p, rest)
        | _ ->
            let next, rest = parse_program rest in_behavior in
            (Ast.Program (p, next), rest))
    | _ -> (Ast.Empty, tokens)
  and parse_behavior tokens =
    let rec parse_args opening tokens acc =
      match tokens with
      | { value = Token.Colon; _ } :: tokens -> (tokens, List.rev acc)
      | { value = Token.RuntimeVal a; _ } :: tokens ->
          parse_args opening tokens (a :: acc)
      | [] -> throw @@ UnclosedBehavior opening.span
      | guilty_token :: _ when acc <> [] ->
          unexpected guilty_token [ BehaviorColon ]
      | _ -> (tokens, List.rev acc)
    in
    match tokens with
    | ({ value = Token.OpeningBracket; _ } as opening) :: tokens -> (
        let tokens, args = parse_args opening tokens [] in
        let body, rest = parse_program tokens true in
        match rest with
        | { value = Token.ClosingBracket } :: rest ->
            Some (Ast.Behavior (args, body), rest)
        | [] -> throw @@ UnclosedBehavior opening.span
        | t :: _ -> unexpected t [ Parse_error.ClosingBracket ])
    | _ -> None
  in

  let ast, rest = parse_program tokens false in
  match rest with [] -> ast | token :: _ -> unexpected token []
