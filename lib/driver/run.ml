open Ast
open Env
open Lexer
open Parser
open Eval

let run prog =
  try
    match lex prog |> parse with
    | Some tree ->
        let tree, e = eval tree in
        (Some tree, e)
    | None -> (None, Env.create ())
  with Lexer.Lexing_error e ->
    prerr_endline (Lexer.string_of_lex_error e);
    exit 1
