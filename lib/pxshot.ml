(* Pxshot - Official OCaml SDK for the Pxshot screenshot API *)

open Lwt.Syntax

(* Types *)

type format =
  | Png
  | Jpeg
  | Webp

type wait_until =
  | Load
  | Domcontentloaded
  | Networkidle

type screenshot_options = {
  url : string;
  format : format option;
  quality : int option;
  width : int option;
  height : int option;
  full_page : bool option;
  wait_until : wait_until option;
  wait_for_selector : string option;
  wait_for_timeout : int option;
  device_scale_factor : float option;
  store : bool option;
  block_ads : bool option;
}

type stored_screenshot = {
  url : string;
  expires_at : string;
  width : int;
  height : int;
  size_bytes : int;
}

type screenshot_response =
  | Bytes of bytes
  | Stored of stored_screenshot

type usage = {
  screenshots_taken : int;
  screenshots_limit : int;
  bytes_used : int;
  bytes_limit : int;
  period_start : string;
  period_end : string;
}

type error =
  | Unauthorized of string
  | BadRequest of string
  | RateLimited of string
  | ServerError of string
  | NetworkError of string
  | ParseError of string

(* Client *)

type t = {
  api_key : string;
  base_url : string;
}

let default_base_url = "https://api.pxshot.com"

let create ?(base_url = default_base_url) api_key =
  { api_key; base_url }

(* Helpers *)

let format_to_string = function
  | Png -> "png"
  | Jpeg -> "jpeg"
  | Webp -> "webp"

let wait_until_to_string = function
  | Load -> "load"
  | Domcontentloaded -> "domcontentloaded"
  | Networkidle -> "networkidle"

let error_to_string = function
  | Unauthorized msg -> Printf.sprintf "Unauthorized: %s" msg
  | BadRequest msg -> Printf.sprintf "Bad request: %s" msg
  | RateLimited msg -> Printf.sprintf "Rate limited: %s" msg
  | ServerError msg -> Printf.sprintf "Server error: %s" msg
  | NetworkError msg -> Printf.sprintf "Network error: %s" msg
  | ParseError msg -> Printf.sprintf "Parse error: %s" msg

(* Internal helpers *)

let headers client =
  Cohttp.Header.of_list [
    ("Authorization", "Bearer " ^ client.api_key);
    ("Content-Type", "application/json");
    ("User-Agent", "pxshot-ocaml/0.1.0");
  ]

let handle_response resp body =
  let status = Cohttp.Response.status resp in
  let code = Cohttp.Code.code_of_status status in
  match code with
  | 200 | 201 -> Ok body
  | 400 -> Error (BadRequest body)
  | 401 -> Error (Unauthorized body)
  | 429 -> Error (RateLimited body)
  | c when c >= 500 -> Error (ServerError body)
  | _ -> Error (ServerError (Printf.sprintf "Unexpected status %d: %s" code body))

(* Screenshot *)

let build_screenshot_body ~url ?format ?quality ?width ?height ?full_page
    ?wait_until ?wait_for_selector ?wait_for_timeout ?device_scale_factor ?store ?block_ads () =
  let fields = [("url", `String url)] in
  let fields = match format with
    | Some f -> ("format", `String (format_to_string f)) :: fields
    | None -> fields
  in
  let fields = match quality with
    | Some q -> ("quality", `Int q) :: fields
    | None -> fields
  in
  let fields = match width with
    | Some w -> ("width", `Int w) :: fields
    | None -> fields
  in
  let fields = match height with
    | Some h -> ("height", `Int h) :: fields
    | None -> fields
  in
  let fields = match full_page with
    | Some fp -> ("full_page", `Bool fp) :: fields
    | None -> fields
  in
  let fields = match wait_until with
    | Some wu -> ("wait_until", `String (wait_until_to_string wu)) :: fields
    | None -> fields
  in
  let fields = match wait_for_selector with
    | Some sel -> ("wait_for_selector", `String sel) :: fields
    | None -> fields
  in
  let fields = match wait_for_timeout with
    | Some t -> ("wait_for_timeout", `Int t) :: fields
    | None -> fields
  in
  let fields = match device_scale_factor with
    | Some dsf -> ("device_scale_factor", `Float dsf) :: fields
    | None -> fields
  in
  let fields = match store with
    | Some s -> ("store", `Bool s) :: fields
    | None -> fields
  in
  let fields = match block_ads with
    | Some ba -> ("block_ads", `Bool ba) :: fields
    | None -> fields
  in
  `Assoc fields

let parse_stored_screenshot body =
  try
    let json = Yojson.Safe.from_string body in
    let url = Yojson.Safe.Util.(member "url" json |> to_string) in
    let expires_at = Yojson.Safe.Util.(member "expires_at" json |> to_string) in
    let width = Yojson.Safe.Util.(member "width" json |> to_int) in
    let height = Yojson.Safe.Util.(member "height" json |> to_int) in
    let size_bytes = Yojson.Safe.Util.(member "size_bytes" json |> to_int) in
    Ok { url; expires_at; width; height; size_bytes }
  with e ->
    Error (ParseError (Printf.sprintf "Failed to parse stored screenshot response: %s" (Printexc.to_string e)))

let screenshot client ~url ?format ?quality ?width ?height ?full_page
    ?wait_until ?wait_for_selector ?wait_for_timeout ?device_scale_factor ?store ?block_ads () =
  let uri = Uri.of_string (client.base_url ^ "/v1/screenshot") in
  let body_json = build_screenshot_body ~url ?format ?quality ?width ?height
      ?full_page ?wait_until ?wait_for_selector ?wait_for_timeout 
      ?device_scale_factor ?store ?block_ads () in
  let body_str = Yojson.Safe.to_string body_json in
  let body = Cohttp_lwt.Body.of_string body_str in
  Lwt.catch
    (fun () ->
      let* (resp, body) = Cohttp_lwt_unix.Client.post ~headers:(headers client) ~body uri in
      let* body_str = Cohttp_lwt.Body.to_string body in
      match handle_response resp body_str with
      | Error e -> Lwt.return (Error e)
      | Ok body ->
        (* Check content-type to determine if it's JSON (stored) or binary (bytes) *)
        let content_type = 
          Cohttp.Response.headers resp 
          |> (fun h -> Cohttp.Header.get h "content-type")
          |> Option.value ~default:""
        in
        let is_json = String.length content_type >= 16 && 
                      String.sub content_type 0 16 = "application/json" in
        if is_json || store = Some true then
          match parse_stored_screenshot body with
          | Ok stored -> Lwt.return (Ok (Stored stored))
          | Error e -> Lwt.return (Error e)
        else
          Lwt.return (Ok (Bytes (Bytes.of_string body))))
    (fun e ->
      Lwt.return (Error (NetworkError (Printexc.to_string e))))

(* Usage *)

let parse_usage body =
  try
    let json = Yojson.Safe.from_string body in
    let open Yojson.Safe.Util in
    let screenshots_taken = member "screenshots_taken" json |> to_int in
    let screenshots_limit = member "screenshots_limit" json |> to_int in
    let bytes_used = member "bytes_used" json |> to_int in
    let bytes_limit = member "bytes_limit" json |> to_int in
    let period_start = member "period_start" json |> to_string in
    let period_end = member "period_end" json |> to_string in
    Ok { screenshots_taken; screenshots_limit; bytes_used; bytes_limit; period_start; period_end }
  with e ->
    Error (ParseError (Printf.sprintf "Failed to parse usage response: %s" (Printexc.to_string e)))

let get_usage client =
  let uri = Uri.of_string (client.base_url ^ "/v1/usage") in
  Lwt.catch
    (fun () ->
      let* (resp, body) = Cohttp_lwt_unix.Client.get ~headers:(headers client) uri in
      let* body_str = Cohttp_lwt.Body.to_string body in
      match handle_response resp body_str with
      | Error e -> Lwt.return (Error e)
      | Ok body -> Lwt.return (parse_usage body))
    (fun e ->
      Lwt.return (Error (NetworkError (Printexc.to_string e))))
