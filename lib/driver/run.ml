open Env
open Lexer
open Parser
open Eval

let run prog =
  try
    let tree, e = prog |> lex |> parse |> eval in
    (Some tree, e)
  with
  | Lexer.Lexing_error e ->
      prerr_endline (Lexer.string_of_lex_error e);
      exit 1
  | Parse_error.Parsing_error e ->
      prerr_endline (Parse_error.to_string e);
      exit 1
