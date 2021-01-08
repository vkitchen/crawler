open Lwt
open Cohttp_lwt_unix

let sites: string list =
  [ "http://vaughan.kitchen"
  ; "http://potatocastles.com"
  ; "http://ambersong.me"
  ]

let body (site : string) : unit t =
  Client.get (Uri.of_string site) >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string >>= fun body ->
  print_endline body;
  Lwt.return ()

let () =
  Lwt_main.run (Lwt.join (List.map body sites))
