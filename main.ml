open Lwt
open Cohttp_lwt_unix

let body =
  Client.get (Uri.of_string "http://vaughan.kitchen") >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string >|= fun body ->
  body

let () =
  let body = Lwt_main.run body in
  print_endline body
