type lex_error = Unexpected_character of Position.t * char

let string_of_lex_error = function
  | Unexpected_character (pos, c) ->
      Printf.sprintf
        "Lexing error at line %d, column %d: unexpected character '%c'" pos.line
        pos.column c

exception Lexing_error of lex_error

let throw e = raise @@ Lexing_error e

type context = {
  input : string;
  mutable pos : Position.t;
  mutable offset : int;
}

let create_context input = { input; pos = Position.start (); offset = 0 }
let is_over (ctx : context) : bool = ctx.offset >= String.length ctx.input

let int_of_char_list chars =
  chars |> List.to_seq |> String.of_seq |> int_of_string

let peek (ctx : context) : char option =
  if is_over ctx then Option.None else Option.Some ctx.input.[ctx.offset]

let peek_at (ctx : context) (at : int) : char option =
  if is_over ctx || String.length ctx.input <= at then Option.None
  else Option.Some ctx.input.[at]

let clone_pos ctx = Position.create ctx.pos.line ctx.pos.column

let consume ctx =
  Option.map
    (fun c ->
      ctx.pos <- Position.advance ctx.pos c;
      ctx.offset <- ctx.offset + 1;
      c)
    (peek ctx)

let consume_if (f : char -> bool) (ctx : context) : char option =
  Option.bind (peek ctx) (fun c -> if f c then consume ctx else None)

let rec consume_full_line ctx =
  match consume ctx with
  | Some '\n' -> true
  | Some _ -> consume_full_line ctx
  | None -> false

let rec consume_multiline_comment ctx =
  if String_utils.starts_with_at ctx.input ctx.offset "*/" then
    let _ = consume ctx in
    let _ = consume ctx in
    true
  else
    match consume ctx with
    | Some _ -> consume_multiline_comment ctx
    | None -> false

let rec skip_seps (ctx : context) : unit =
  if is_over ctx then ()
  else if String_utils.starts_with_at ctx.input ctx.offset "//" then
    let _ = consume_full_line ctx in
    skip_seps ctx
  else if String_utils.starts_with_at ctx.input ctx.offset "/*" then
    let _ = consume_multiline_comment ctx in
    skip_seps ctx
  else if Option.is_some (consume_if String_utils.is_sep ctx) then skip_seps ctx
  else ()

type handler = { try_consume : context -> Token.t Located.t option }

let unit_h : handler =
  {
    try_consume =
      (fun ctx ->
        match (peek ctx, peek_at ctx (ctx.offset + 1)) with
        | Some '(', Some ')' ->
            let p1 = clone_pos ctx in
            let _ = consume ctx in
            let _ = consume ctx in
            let p2 = clone_pos ctx in
            Some (Located.create p1 p2 Token.Unit)
        | _ -> None);
  }

let symbol_h : handler =
  {
    try_consume =
      (fun ctx ->
        Option.bind (peek ctx) (function
          | '@' -> Some Token.At
          | '$' -> Some Token.Dollar
          | ':' -> Some Token.Colon
          | '{' -> Some Token.OpeningBracket
          | '}' -> Some Token.ClosingBracket
          | _ -> None)
        |> Option.map (fun token ->
            let p1 = clone_pos ctx in
            let _ = consume ctx in
            let p2 = clone_pos ctx in
            Located.create p1 p2 token));
  }

let op_h : handler =
  {
    try_consume =
      (fun ctx ->
        let offset1 = ctx.offset in
        let rec work offset2 dash_count =
          if offset2 >= String.length ctx.input then None
          else
            Option.bind (peek_at ctx offset2) (fun c ->
                if c = '-' || c = '~' then
                  if dash_count = 2 then None
                  else work (offset2 + 1) (dash_count + 1)
                else if String_utils.is_digit c || c = '_' then
                  if dash_count = 0 then None else work (offset2 + 1) dash_count
                else if c = '>' then
                  if dash_count = 0 then None
                  else
                    let length = offset2 - offset1 + 1 in
                    let op =
                      String.sub ctx.input offset1 length |> Operator.of_string
                    in
                    Some (op, length)
                else None)
        in

        work offset1 0
        |> Option.map (fun (op, length) ->
            let p1 = clone_pos ctx in
            for i = 0 to length - 1 do
              let _ =
                consume ctx
                |> Option_utils.unwrap_or_else (fun () ->
                    failwith "internal lexer invariant broken")
              in
              ()
            done;
            let p2 = clone_pos ctx in
            Token.Operator op |> Located.create p1 p2));
  }

let number_h : handler =
  {
    try_consume =
      (fun ctx ->
        let p1 = clone_pos ctx in
        Option.bind (peek ctx) (fun c ->
            if String_utils.is_digit c then
              let rec work acc =
                match consume_if String_utils.is_digit ctx with
                | Some c -> work (c :: acc)
                | None -> List.rev acc
              in
              let n = work [] in
              let p2 = clone_pos ctx in
              Some (Token.Number (int_of_char_list n) |> Located.create p1 p2)
            else None));
  }

let is_valid_ident_symbol (c : char) : bool = String.contains "_+!-'" c

let is_valid_ident_first_char (c : char) : bool =
  String_utils.is_alpha c || is_valid_ident_symbol c

let is_valid_ident_char (c : char) : bool =
  String_utils.is_digit c || String_utils.is_alpha c || is_valid_ident_symbol c

let ident_h : handler =
  {
    try_consume =
      (fun ctx ->
        let p1 = clone_pos ctx in
        Option.bind (peek ctx) (fun c ->
            let is_arg = c = '\'' in
            if is_arg || is_valid_ident_first_char c then
              let rec work acc =
                match consume_if is_valid_ident_char ctx with
                | Some c -> work (c :: acc)
                | None -> List.rev acc
              in
              let name = work [] in
              let p2 = clone_pos ctx in
              (if is_arg then
                 match name with
                 | [] -> None
                 | _ :: name ->
                     Some (Token.Arg (String_utils.string_of_char_list name))
               else Some (Token.Ident (String_utils.string_of_char_list name)))
              |> Option.map @@ Located.create p1 p2
            else None));
  }

let all_handlers = [ number_h; op_h; symbol_h; unit_h; ident_h ]

let next_token ctx =
  if is_over ctx then None
  else List.find_map (fun h -> h.try_consume ctx) all_handlers

let lex s =
  let rec work acc ctx =
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
