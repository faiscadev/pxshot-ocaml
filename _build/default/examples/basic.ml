(* Basic screenshot example *)

open Lwt.Syntax

let () =
  let api_key = Sys.getenv_opt "PXSHOT_API_KEY" 
    |> Option.value ~default:"px_your_api_key" in
  let client = Pxshot.create api_key in
  
  Lwt_main.run begin
    let* result = Pxshot.screenshot client
      ~url:"https://example.com"
      ~format:Pxshot.Png
      ~width:1280
      ~height:720
      () in
    
    match result with
    | Ok (Pxshot.Bytes data) ->
      let filename = "screenshot.png" in
      let oc = open_out_bin filename in
      output_bytes oc data;
      close_out oc;
      Printf.printf "Screenshot saved to %s (%d bytes)\n" filename (Bytes.length data);
      Lwt.return_unit
    | Ok (Pxshot.Stored _) ->
      Printf.printf "Unexpected stored response\n";
      Lwt.return_unit
    | Error e ->
      Printf.eprintf "Error: %s\n" (Pxshot.error_to_string e);
      Lwt.return_unit
  end
