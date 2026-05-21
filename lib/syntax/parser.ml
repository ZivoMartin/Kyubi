open Ast
open Token
open Operator

type parse_error = IncorrectBeginningOfFlow | InvalidFlowMember

exception Parsing_error of parse_error

let throw e = raise @@ Parsing_error e

let parse (tokens : token list) : ast option =
  let rec parse_one_flow (first : ast) (acc : (operator * ast) list)
      (tokens : token list) : ast * token list =
    let return (_ : unit) : ast * token list =
      (Ast.Flow (first, List.rev acc), tokens)
    in
    match tokens with
    | Token.Operator op :: right :: rest ->
        let right_ast =
          match right with
          | Token.Ident name -> Ast.Ident name
          | _ -> throw InvalidFlowMember
        in
        parse_one_flow first ((op, right_ast) :: acc) rest
    | _ -> return ()
  in

  let rec parse_program (tokens : token list) : ast option =
    match tokens with
    | [] -> None
    | first :: tokens ->
        let first =
          match first with
          | Token.Ident name -> Ast.Ident name
          | Token.Number n -> Ast.Value (Value.Number n)
          | _ -> throw IncorrectBeginningOfFlow
        in
        let tree, rest = parse_one_flow first [] tokens in
        Some (Ast.Program (tree, parse_program rest))
  in

  parse_program tokens
