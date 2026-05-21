open Kyubi.Env
open Kyubi.Run
open Kyubi.Lexer

let () =
  if Array.length Sys.argv < 2 then
    Printf.eprintf "Usage: %s <file>\n" Sys.argv.(0)
  else
    let filename = Sys.argv.(1) in
    Printf.printf "File: %s\n" filename;
    let content = In_channel.with_open_text filename In_channel.input_all in
    let _, e = run content in
    print_endline (Kyubi.Env.string_of_env e)
