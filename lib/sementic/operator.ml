type t =
  | Enqueue of Flow_size.t
  | Produce of Flow_size.t * Flow_size.t
  | Benqueue of Flow_size.t
  | Promote of Flow_size.t
  | Demote of Flow_size.t

let to_string = function
  | Enqueue f -> Flow_size.to_string f |> Printf.sprintf "-%s>"
  | Benqueue f -> Flow_size.to_string f |> Printf.sprintf "~%s>"
  | Promote f -> Flow_size.to_string f |> Printf.sprintf "-%s~>"
  | Demote f -> Flow_size.to_string f |> Printf.sprintf "~%s->"
  | Produce (f1, f2) ->
      Printf.sprintf "-%s-%s>" (Flow_size.to_string f1) (Flow_size.to_string f2)

let of_string s =
  let fail () =
    invalid_arg (Printf.sprintf "operator_of_string: invalid operator %S" s)
  in

  let length = String.length s in
  let rec parse offset =
    if offset = length then fail ()
    else
      let c = s.[offset] in
      match c with
      | '>' -> if offset + 1 = length then (offset, [], []) else fail ()
      | '~' | '-' ->
          let p1 = offset + 1 in
          let p2, dashes, flows = parse (offset + 1) in
          let flow =
            (if p2 < p1 then "" else String.sub s p1 (p2 - p1))
            |> Flow_size.of_string
          in
          (offset, c :: dashes, flow :: flows)
      | _ when String_utils.is_digit c || c = '_' -> parse (offset + 1)
      | _ -> fail ()
  in

  let flow_should_be_absent = function
    | Flow_size.Absent -> ()
    | _ -> fail ()
  in

  let offset, dashes, flows = parse 0 in
  if offset <> 0 then fail ()
  else
    match (dashes, flows) with
    | [ '-'; '-' ], [ f1; f2 ] -> Produce (f1, f2)
    | [ '-' ], [ f ] -> Enqueue f
    | [ '~' ], [ f ] -> Benqueue f
    | [ '-'; '~' ], [ f1; f2 ] ->
        flow_should_be_absent f2;
        Promote f1
    | [ '~'; '-' ], [ f1; f2 ] ->
        flow_should_be_absent f2;
        Demote f1
    | _ -> fail ()
