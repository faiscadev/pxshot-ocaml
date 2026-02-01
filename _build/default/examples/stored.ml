(* Stored screenshot example - returns a URL instead of bytes *)

open Lwt.Syntax

let () =
  let api_key = Sys.getenv_opt "PXSHOT_API_KEY" 
    |> Option.value ~default:"px_your_api_key" in
  let client = Pxshot.create api_key in
  
  Lwt_main.run begin
    let* result = Pxshot.screenshot client
      ~url:"https://example.com"
      ~format:Pxshot.Webp
      ~width:1920
      ~height:1080
      ~full_page:true
      ~wait_until:Pxshot.Networkidle
      ~store:true
      () in
    
    match result with
    | Ok (Pxshot.Stored info) ->
      Printf.printf "Screenshot stored!\n";
      Printf.printf "  URL: %s\n" info.url;
      Printf.printf "  Expires: %s\n" info.expires_at;
      Printf.printf "  Size: %dx%d (%d bytes)\n" info.width info.height info.size_bytes;
      Lwt.return_unit
    | Ok (Pxshot.Bytes _) ->
      Printf.printf "Unexpected bytes response\n";
      Lwt.return_unit
    | Error e ->
      Printf.eprintf "Error: %s\n" (Pxshot.error_to_string e);
      Lwt.return_unit
  end
