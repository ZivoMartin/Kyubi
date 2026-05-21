open Token

type position = { line : int; column : int }
type lex_error = Unexpected_character of position * char

val string_of_lex_error : lex_error -> string

exception Lexing_error of lex_error

val lex : string -> token list
