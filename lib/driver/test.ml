open Lexer
open Parser
open Eval

let run prog =
  let tree, e = prog |> lex |> parse |> eval in
  (Some tree, e)
