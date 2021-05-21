open Sqlite3

let () =
  let db = db_open "db/db.db" in
  ignore (exec_not_null_no_headers db ~cb:(fun r -> Array.iter print_endline r) "select * from sites");
  Printf.printf "SQLite Version: %d\n" (sqlite_version ())
