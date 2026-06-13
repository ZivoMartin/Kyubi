type expectation = FlowStart | FlowComponent | BehaviorColon | ClosingBracket

type t =
  | UnexpectedToken of {
      found : Token.t Located.t;
      expected : expectation list;
    }
  | SpecialQueueOutOfBehavior of Token.t Located.t
  | UnclosedBehavior of Span.t
  | CannotEnqueueInput of Token.t Located.t
  | CannotDequeueOutput of Token.t Located.t

exception Parsing_error of t

val to_string : t -> string
