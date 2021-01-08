open Lwt
open Cohttp_lwt_unix
open Soup

let sites: string list =
  [ "http://vaughan.kitchen"
  ; "http://potatocastles.com"
  ; "http://ambersong.me"
  ]

let links (page : string) : string list =
  let soup = parse page in
  soup $$ "a[href]"
  |> to_list
  |> List.map (fun a -> a |> R.attribute "href")

let fetch (site : string) : unit t =
  Client.get (Uri.of_string site) >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string >>= fun b ->
    links b
    |> List.filter (fun l -> String.index_opt l '#' <> Some 0)
    |> List.map (fun l -> String.concat "/" (site :: l :: []) )
    |> List.iter print_endline;
    Lwt.return ()

let () =
  Lwt_main.run (Lwt.join (List.map fetch sites))
