open Lwt
open Cohttp_lwt_unix
open Soup

let sites: string list =
  [ "http://vaughan.kitchen"
  ; "http://ambersong.me"
  ]

let cons_uniq xs x =
  if List.mem x xs then
    xs
  else
    x :: xs

let dedupe xs =
  List.rev (List.fold_left cons_uniq [] xs)

let links (page : string) : string list =
  let soup = parse page in
  soup $$ "a[href]"
  |> to_list
  |> List.map (fun a -> a |> R.attribute "href")

let fetch (site : string) : string list t =
  let site_uri = Uri.of_string site in
  Client.get site_uri >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string >>= fun b ->
    links b
      |> List.filter (fun l -> String.index_opt l '#' <> Some 0) (*remove fragment URIs*)
      |> List.filter (fun l -> Uri.host (Uri.of_string l) = None) (* remove external URIs*)
      |> List.map (fun l -> Uri.with_path site_uri l)
      |> List.map Uri.canonicalize
      |> List.map Uri.to_string
      |> Lwt.return

let rec scrape (fetched : string list) (queue : string list) : unit t =
  match queue with
  | [] -> Lwt.return ()
  | x :: tl ->
    print_endline x;
    (*
    List.iter (fun l -> print_endline ("  F  " ^ l)) fetched;
    List.iter (fun l -> print_endline ("  Q  " ^ l)) tl;
    *)
    let%lwt q = fetch x in
    let q = List.filter (fun l -> l <> x && not (List.exists (fun l_ -> l = l_) fetched)) q in
    scrape (x :: fetched) (dedupe (tl @ q))

let () =
  Lwt_main.run (Lwt.join (List.map (fun s -> scrape [] (s :: [])) sites))
