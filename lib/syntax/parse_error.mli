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

val to_string : t -> string
