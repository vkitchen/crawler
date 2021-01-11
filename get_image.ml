open Lwt
open Cohttp_lwt_unix
open Soup

let write_file body out_path =
  let fh = open_out out_path in
  Printf.fprintf fh "%s" body;
  close_out fh

let fetch img out_path =
  let site_uri = Uri.of_string img in
  try%lwt Client.get site_uri >>= fun (_, body) ->
    body |> Cohttp_lwt.Body.to_string >>= fun b ->
      write_file b out_path;
      Lwt.return ""
  with _ ->
    Lwt.return "Error during fetch"

let body =
  if Array.length Sys.argv <> 3 then
    Lwt.return "Failed: Incorrect number of args"
  else
    let fh = open_in Sys.argv.(1) in
    let soup = read_channel fh |> parse in
    let images = soup $$ "img"
    |> to_list
    |> List.map (fun a -> a |> R.attribute "src")
    |> List.filter (fun a -> Str.string_match (Str.regexp {|.*\.jpg|}) a 0)
    |> List.filter (fun a -> a <> "https://i2.wp.com/www.vegrecipesofindia.com/wp-content/uploads/2019/11/dassana.jpg")
    in
    match images with
      | [] -> Lwt.return ("No image " ^ Sys.argv.(1))
      | img :: _ ->
        fetch img Sys.argv.(2)

let () =
  let body = Lwt_main.run body in
  print_endline body
