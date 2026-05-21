let is_sep = String.contains " \n\t\r"
let string_of_char_list chars = chars |> List.to_seq |> String.of_seq

let starts_with_at s i prefix =
  let len_s = String.length s in
  let len_p = String.length prefix in
  i + len_p <= len_s
  &&
  let rec loop j = j = len_p || (s.[i + j] = prefix.[j] && loop (j + 1)) in
  loop 0

let is_alpha c = ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z')
let is_digit c = '0' <= c && c <= '9'
