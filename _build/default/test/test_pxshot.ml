(* Tests for Pxshot OCaml SDK *)

open Pxshot

(* Test helpers *)

let test_format_to_string () =
  Alcotest.(check string) "png" "png" (format_to_string Png);
  Alcotest.(check string) "jpeg" "jpeg" (format_to_string Jpeg);
  Alcotest.(check string) "webp" "webp" (format_to_string Webp)

let test_wait_until_to_string () =
  Alcotest.(check string) "load" "load" (wait_until_to_string Load);
  Alcotest.(check string) "domcontentloaded" "domcontentloaded" (wait_until_to_string Domcontentloaded);
  Alcotest.(check string) "networkidle" "networkidle" (wait_until_to_string Networkidle)

let test_error_to_string () =
  Alcotest.(check string) "unauthorized" 
    "Unauthorized: invalid key" 
    (error_to_string (Unauthorized "invalid key"));
  Alcotest.(check string) "bad request" 
    "Bad request: missing url" 
    (error_to_string (BadRequest "missing url"));
  Alcotest.(check string) "rate limited" 
    "Rate limited: too many requests" 
    (error_to_string (RateLimited "too many requests"));
  Alcotest.(check string) "server error" 
    "Server error: internal error" 
    (error_to_string (ServerError "internal error"));
  Alcotest.(check string) "network error" 
    "Network error: connection refused" 
    (error_to_string (NetworkError "connection refused"));
  Alcotest.(check string) "parse error" 
    "Parse error: invalid json" 
    (error_to_string (ParseError "invalid json"))

let test_create_client () =
  let client = create "test_api_key" in
  (* Client is opaque, just verify it doesn't crash *)
  ignore client;
  Alcotest.(check pass) "client created" () ()

let test_create_client_with_base_url () =
  let client = create ~base_url:"https://custom.api.com" "test_api_key" in
  ignore client;
  Alcotest.(check pass) "client with custom base url created" () ()

(* Test suite *)

let unit_tests = [
  "format_to_string", `Quick, test_format_to_string;
  "wait_until_to_string", `Quick, test_wait_until_to_string;
  "error_to_string", `Quick, test_error_to_string;
  "create_client", `Quick, test_create_client;
  "create_client_with_base_url", `Quick, test_create_client_with_base_url;
]

let () =
  Alcotest.run "Pxshot" [
    "unit", unit_tests;
  ]
