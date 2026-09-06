let base_cap = 10

type 'v map = (string, 'v) Hashtbl.t

type 'v t = {
  mutable pattern_bindings : 'v map;
  mutable args_bindings : 'v map;
}

let create () =
  {
    pattern_bindings = Hashtbl.create base_cap;
    args_bindings = Hashtbl.create base_cap;
  }

let add_pat_binding b = Hashtbl.add b.pattern_bindings
let add_arg_binding b = Hashtbl.add b.pattern_bindings
let set_pat b pattern_bindings = b.pattern_bindings <- pattern_bindings
let set_args b args_bindings = b.args_bindings <- args_bindings

let get b name =
  Hashtbl.find_opt b.pattern_bindings name
  |> Option_utils.or_else (fun () -> Hashtbl.find_opt b.args_bindings name)
