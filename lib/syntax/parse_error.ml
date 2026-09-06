type expectation =
  | FlowStart
  | FlowComponent
  | BehaviorColon
  | ClosingBracket
  | ClosingSBracket
  | SerieComma
  | BranchingBar
  | BranchingCloser

type t =
  | UnexpectedToken of {
      found : Token.t Located.t;
      expected : expectation list;
    }
  | UnexpectedEOF of expectation list
  | SpecialQueueOutOfBehavior of Token.t Located.t
  | UnclosedBehavior of Span.t
  | UnclosedSerie of Span.t
  | UnclosedBranching of Span.t
  | CannotEnqueueInput of Token.t Located.t
  | CannotDequeueOutput of Token.t Located.t
  | InvalidFlowInBranch of Span.t
  | InvalidPatternInBranch of Span.t

exception Parsing_error of t

let string_of_expectation = function
  | FlowStart -> "a flow start"
  | FlowComponent -> "a flow component"
  | BehaviorColon -> "':'"
  | ClosingBracket -> "'}'"
  | ClosingSBracket -> "']'"
  | SerieComma -> "','"
  | BranchingBar -> "'|'"
  | BranchingCloser -> "'|>'"

let string_of_expectations = function
  | [] -> "nothing in particular"
  | [ e ] -> string_of_expectation e
  | expectations ->
      String.concat ", " (List.map string_of_expectation expectations)

let to_string = function
  | UnexpectedToken { found; expected } ->
      Printf.sprintf "%s: unexpected token \"%s\", expected %s"
        (Span.to_string found.span)
        (Token.to_string found.value)
        (string_of_expectations expected)
  | SpecialQueueOutOfBehavior token ->
      Printf.sprintf "%s: special queue %s may only be used inside a behavior"
        (Span.to_string token.span)
        (Token.to_string token.value)
  | UnclosedBehavior span ->
      Printf.sprintf "%s: unclosed behavior, missing closing '}'"
        (Span.to_string span)
  | UnclosedSerie span ->
      Printf.sprintf "%s: unclosed serie, missing closing ']'"
        (Span.to_string span)
  | UnclosedBranching span ->
      Printf.sprintf "%s: unclosed branching, missing closing '|>'"
        (Span.to_string span)
  | CannotDequeueOutput token ->
      Printf.sprintf "%s: cannot dequeue the output special queue."
        (Span.to_string token.span)
  | CannotEnqueueInput token ->
      Printf.sprintf "%s: cannot enqueue in the input special queue."
        (Span.to_string token.span)
  | InvalidFlowInBranch span ->
      Printf.sprintf "%s: This branch does not have a correct flow."
        (Span.to_string span)
  | InvalidPatternInBranch span ->
      Printf.sprintf "%s: This branch does not have a correct pattern."
        (Span.to_string span)
  | UnexpectedEOF expected ->
      Printf.sprintf "Unexpected EOF, expected %s"
        (string_of_expectations expected)
