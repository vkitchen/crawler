open Lwt
open Cohttp_lwt_unix
open Soup

(*
  TODO
  - path relative to subdirs (misses gardening pages on vaughan.kitchen)
*)

(*
let sites: string list =
  [ "http://vaughan.kitchen"
  ; "http://ambersong.me"
  ]
*)
let sites: string list =
  [ "https://thegentlechef.com"
  ; "https://spicysouthernkitchen.com"
  ; "https://lazycatkitchen.com"
  ; "https://www.asaucykitchen.com"
  ; "https://www.vegrecipesofindia.com"
  ; "https://thecaspianchef.com"
  ; "https://persianmama.com"
  ; "https://www.unicornsinthekitchen.com"
  ; "https://thestonesoup.com"
  ; "https://www.afamilyfeast.com"
  ; "https://hilahcooking.com"
  ; "https://www.gimmesomeoven.com"
  ; "https://www.chilipeppermadness.com" (* key too small *)
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

let mkdir_p (path : string) : bool =
  if Sys.file_exists path && Sys.is_directory path then
    true
  else if Sys.file_exists path then begin
    print_endline ("Failed to create path '" ^ path ^ "' already exists");
    false
  end else
    let chunks = Str.split (Str.regexp "/+") path in
    match chunks with
      | [] -> false
      | x :: tl ->
        if tl = [] then
          if not (Sys.file_exists x) then begin
            Unix.mkdir x 0o777;
            true
          end else
            false (* ?? *)
        else
          List.fold_left (fun x xs ->
            let res = x ^ "/" ^ xs in
            (if not (Sys.file_exists res) then
              Unix.mkdir res 0o777
            else
              ());
            res
          ) x tl <> "" (* bad hack *)

let write_file (site : string) (body : string): unit =
  let site_uri = Uri.of_string site in
  let host = match Uri.host site_uri with
    | None -> ""
    | Some x -> x
  in
  let path = Uri.path site_uri in
  if path = "" || host = "" then
    ()
  else
    let chunks = Str.split (Str.regexp "/+") path in
    match List.rev chunks with
      | [] -> ()
      | x :: tl ->
        let tl = List.rev tl in
        let dir = String.concat "/" (host :: tl) in
        if mkdir_p dir then
          let filename = dir ^ "/" ^ x ^ ".ccml" in
          if Sys.file_exists filename then
            print_endline ("Failed to write '" ^ filename ^ "' file already exists")
          else
            let fh = open_out filename in
            Printf.fprintf fh "%s\n" body;
            close_out fh
        else
          () (* should be error? *)

let fetch (site : string) : string list t =
  let site_uri = Uri.of_string site in
  try%lwt Client.get site_uri >>= fun (_, body) ->
    body |> Cohttp_lwt.Body.to_string >>= fun b ->
      write_file site b; (* write out html *)
      links b
        |> List.filter (fun l -> String.index_opt l '#' <> Some 0) (* remove fragment URIs *)
        |> List.filter (fun l -> Uri.host (Uri.of_string l) = None) (* remove external URIs *)
        |> List.map (fun l -> Uri.with_path site_uri (Uri.path (Uri.of_string l))) (* TODO fix bug with query fragments *)
        |> List.map Uri.canonicalize
        |> List.map Uri.to_string
        |> Lwt.return
  with _ ->
    print_endline ("Failed fetching: " ^ site);
    Lwt.return []

let rec scrape (fetched : string list) (queue : string list) : unit t =
  match queue with
  | [] -> Lwt.return ()
  | x :: tl ->
    Unix.sleep 1;
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
