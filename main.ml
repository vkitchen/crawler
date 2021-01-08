open Lwt
open Cohttp_lwt_unix
open Soup

let sites: string list =
  [ "http://vaughan.kitchen"
  ; "http://potatocastles.com"
  ; "http://ambersong.me"
  ]

let links (page : string) : unit =
  let soup = parse page in
  soup $$ "a[href]"
  |> iter (fun a -> a |> R.attribute "href" |> print_endline)

let fetch (site : string) : unit t =
  Client.get (Uri.of_string site) >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string >|= links

let () =
  Lwt_main.run (Lwt.join (List.map fetch sites))
