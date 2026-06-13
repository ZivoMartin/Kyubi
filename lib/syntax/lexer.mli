type lex_error = Unexpected_character of Position.t * char

val string_of_lex_error : lex_error -> string

exception Lexing_error of lex_error

val lex : string -> Token.t Located.t list
