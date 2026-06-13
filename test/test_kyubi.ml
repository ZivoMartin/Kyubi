type test_entry = {
  program : string;
  expected_env : Kyubi.Env.t;
  actual_env : Kyubi.Env.t;
}

let () =
  let programs_folder = "programs" in
  let result_folder = "result" in

  let read_file (p : string) : string =
    In_channel.with_open_text p In_channel.input_all
  in

  let tests : test_entry list =
    Sys.readdir programs_folder
    |> Array.to_list
    |> List.filter_map (fun prog ->
        match String.split_on_char '.' prog with
        | [ name; "ky" ] ->
            let prog_path = Printf.sprintf "%s/%s" programs_folder prog in
            let result_path = Printf.sprintf "%s/%s" result_folder name in

            let prog_content = read_file prog_path in
            let result_content = read_file result_path in

            print_endline (Printf.sprintf "Running %s..." prog);
            let _, actual_env = Kyubi.Run.run prog_content in
            print_endline (Printf.sprintf "%s ran successfully." prog);
            let expected_env = Kyubi.Env.env_of_string result_content in

            Some { program = prog; expected_env; actual_env }
        | _ ->
            Printf.printf
              "WARN: Invalid format in the program folder : %s. All tests \
               should have the .ky extensions and should not have any other \
               dot in there names."
              prog;
            None)
  in

  match
    List.find_opt
      (fun test ->
        print_endline (Printf.sprintf "Testing %s..." test.program);
        if Kyubi.Env.equal test.expected_env test.actual_env then (
          print_endline (Printf.sprintf "Passed.");
          false)
        else true)
      tests
  with
  | Some test ->
      print_endline
        (Printf.sprintf
           "ERROR: Ouptut is incorrect for program %s. \n\n\
            Expected :\n\
            %s \n\n\
            But got:\n\
            %s"
           test.program
           (Kyubi.Env.string_of_env test.expected_env)
           (Kyubi.Env.string_of_env test.actual_env));
      assert false
  | None ->
      print_endline "All test passed.";
      ()
