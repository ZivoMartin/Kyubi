open Operator
open Token
open String_utils
open Option_utils

type position = { line : int; column : int }
type lex_error = Unexpected_character of position * char

let string_of_lex_error = function
  | Unexpected_character (pos, c) ->
      Printf.sprintf
        "Lexing error at line %d, column %d: unexpected character '%c'" pos.line
        pos.column c

exception Lexing_error of lex_error

let throw e = raise @@ Lexing_error e

type context = { input : string; mutable pos : position; mutable offset : int }

let create_context input = { input; pos = { column = 1; line = 1 }; offset = 0 }
let is_over (ctx : context) : bool = ctx.offset >= String.length ctx.input

let int_of_char_list chars =
  chars |> List.to_seq |> String.of_seq |> int_of_string

let peek (ctx : context) : char option =
  if is_over ctx then Option.None else Option.Some ctx.input.[ctx.offset]

let peek_at (ctx : context) (at : int) : char option =
  if is_over ctx || String.length ctx.input <= at then Option.None
  else Option.Some ctx.input.[at]

let consume ctx =
  Option.map
    (fun c ->
      if c = '\n' then ctx.pos <- { column = 1; line = ctx.pos.line + 1 }
      else ctx.pos <- { column = ctx.pos.column + 1; line = ctx.pos.line };
      ctx.offset <- ctx.offset + 1;
      c)
    (peek ctx)

let consume_if (f : char -> bool) (ctx : context) : char option =
  Option.bind (peek ctx) (fun c -> if f c then consume ctx else None)

let rec skip_seps (ctx : context) : unit =
  if Option.is_some (consume_if String_utils.is_sep ctx) then skip_seps ctx
  else ()

type handler = { try_consume : context -> token option }

let op_h : handler =
  {
    try_consume =
      (fun ctx ->
        let rec parse_dynamic_op acc pos prefix =
          if pos >= String.length ctx.input then None
          else
            let parsing_prefix = acc = [] in
            Option.bind (peek_at ctx pos) (fun c ->
                if String_utils.is_digit c then
                  parse_dynamic_op (c :: acc) (pos + 1) prefix
                else if parsing_prefix then
                  if c = '-' then parse_dynamic_op acc (pos + 1) (c :: prefix)
                  else None
                else if c = '>' then
                  let n = acc |> List.rev |> int_of_char_list in
                  let prefix =
                    prefix |> List.rev |> String_utils.string_of_char_list
                  in

                  match prefix with
                  | "-" -> Some (Operator.EnqueueN n)
                  | "--" -> Some (Operator.ProduceN n)
                  | _ -> None
                else None)
        in

        let parse_static_op () =
          Operator.all_string ()
          |> List.find_opt (String_utils.starts_with_at ctx.input ctx.offset)
          |> Option.map (fun op -> operator_of_string op)
        in

        (match parse_dynamic_op [] ctx.offset [] with
          | Some _ as res -> res
          | None -> parse_static_op ())
        |> Option.map (fun op ->
            let length = String.length (Operator.string_of_operator op) in
            for i = 0 to length - 1 do
              let _ =
                consume ctx
                |> Option_utils.unwrap_or_else (fun () ->
                    failwith "internal lexer invariant broken")
              in
              ()
            done;
            Token.Operator op));
  }

let number_h : handler =
  {
    try_consume =
      (fun ctx ->
        Option.bind (peek ctx) (fun c ->
            if is_digit c then
              let rec work acc =
                match consume_if is_digit ctx with
                | Some c -> work (c :: acc)
                | None -> List.rev acc
              in
              let n = work [] in
              Some (Token.Number (int_of_char_list n))
            else None));
  }

let is_valid_ident_symbol (c : char) : bool = String.contains "_+!-" c

let is_valid_ident_first_char (c : char) : bool =
  String_utils.is_alpha c || is_valid_ident_symbol c

let is_valid_ident_char (c : char) : bool =
  is_digit c || String_utils.is_alpha c || is_valid_ident_symbol c

let ident_h : handler =
  {
    try_consume =
      (fun ctx ->
        Option.bind (peek ctx) (fun c ->
            if is_valid_ident_first_char c then
              let rec work acc =
                match consume_if is_valid_ident_char ctx with
                | Some c -> work (c :: acc)
                | None -> List.rev acc
              in
              let name = work [] in
              Some (Token.Ident (String_utils.string_of_char_list name))
            else None));
  }

let all_handlers = [ number_h; op_h; ident_h ]

let next_token (ctx : context) : token option =
  if is_over ctx then None
  else List.find_map (fun h -> h.try_consume ctx) all_handlers

let lex (s : string) =
  let rec work (acc : token list) (ctx : context) =
    skip_seps ctx;
    match next_token ctx with
    | Option.None -> List.rev acc
    | Option.Some token -> work (token :: acc) ctx
  in
  let ctx = create_context s in
  let tokens = work [] ctx in
  if not (is_over ctx) then
    throw @@ Unexpected_character (ctx.pos, ctx.input.[ctx.offset])
  else tokens
