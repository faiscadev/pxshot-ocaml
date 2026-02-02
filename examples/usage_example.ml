(* Usage statistics example *)

open Lwt.Syntax

let () =
  let api_key = Sys.getenv_opt "PXSHOT_API_KEY" 
    |> Option.value ~default:"px_your_api_key" in
  let client = Pxshot.create api_key in
  
  Lwt_main.run begin
    let* result = Pxshot.get_usage client in
    
    match result with
    | Ok usage ->
      Printf.printf "Pxshot Usage Statistics\n";
      Printf.printf "========================\n";
      Printf.printf "Screenshots: %d / %d\n" usage.screenshots_taken usage.screenshots_limit;
      Printf.printf "Storage: %d / %d bytes\n" usage.bytes_used usage.bytes_limit;
      Printf.printf "Period: %s to %s\n" usage.period_start usage.period_end;
      Lwt.return_unit
    | Error e ->
      Printf.eprintf "Error: %s\n" (Pxshot.error_to_string e);
      Lwt.return_unit
  end
