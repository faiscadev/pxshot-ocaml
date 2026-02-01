# Pxshot OCaml SDK

Official OCaml SDK for the [Pxshot](https://pxshot.com) screenshot API.

[![opam](https://img.shields.io/badge/opam-pxshot-blue)](https://opam.ocaml.org/packages/pxshot/)

## Features

- 🔒 Type-safe API with Result types for error handling
- ⚡ Async operations with Lwt
- 📸 Full screenshot API support (formats, viewport, full-page, selectors)
- ☁️ Cloud storage option (get URLs instead of raw bytes)
- 📊 Usage statistics

## Requirements

- OCaml 4.14+
- opam

## Installation

```bash
opam install pxshot
```

Or add to your `dune-project`:

```lisp
(depends
 (pxshot (>= 0.1.0)))
```

## Quick Start

```ocaml
open Lwt.Syntax

let () =
  let client = Pxshot.create "px_your_api_key" in
  
  Lwt_main.run begin
    (* Capture a screenshot *)
    let* result = Pxshot.screenshot client
      ~url:"https://example.com"
      ~format:Pxshot.Png
      ~width:1280
      ~height:720
      () in
    
    match result with
    | Ok (Pxshot.Bytes data) ->
      let oc = open_out_bin "screenshot.png" in
      output_bytes oc data;
      close_out oc;
      print_endline "Screenshot saved!";
      Lwt.return_unit
    | Ok (Pxshot.Stored info) ->
      Printf.printf "URL: %s\n" info.url;
      Lwt.return_unit
    | Error e ->
      Printf.eprintf "Error: %s\n" (Pxshot.error_to_string e);
      Lwt.return_unit
  end
```

## API Reference

### Creating a Client

```ocaml
(* Default API endpoint *)
let client = Pxshot.create "px_your_api_key"

(* Custom endpoint *)
let client = Pxshot.create ~base_url:"https://custom.api.com" "px_your_api_key"
```

### Taking Screenshots

```ocaml
val screenshot :
  t ->
  url:string ->
  ?format:format ->           (* Png | Jpeg | Webp *)
  ?quality:int ->             (* 1-100, for JPEG/WebP *)
  ?width:int ->               (* Viewport width in pixels *)
  ?height:int ->              (* Viewport height in pixels *)
  ?full_page:bool ->          (* Capture entire scrollable page *)
  ?wait_until:wait_until ->   (* Load | Domcontentloaded | Networkidle *)
  ?wait_for_selector:string -> (* CSS selector to wait for *)
  ?wait_for_timeout:int ->    (* Additional wait in milliseconds *)
  ?device_scale_factor:float -> (* For retina displays *)
  ?store:bool ->              (* Return URL instead of bytes *)
  unit ->
  (screenshot_response, error) result Lwt.t
```

#### Full-Page Screenshot

```ocaml
let* result = Pxshot.screenshot client
  ~url:"https://example.com"
  ~full_page:true
  ~format:Pxshot.Webp
  ~quality:90
  ()
```

#### Wait for Dynamic Content

```ocaml
let* result = Pxshot.screenshot client
  ~url:"https://spa-app.com"
  ~wait_until:Pxshot.Networkidle
  ~wait_for_selector:".content-loaded"
  ~wait_for_timeout:2000
  ()
```

#### Store and Get URL

```ocaml
let* result = Pxshot.screenshot client
  ~url:"https://example.com"
  ~store:true
  () in

match result with
| Ok (Pxshot.Stored info) ->
  Printf.printf "URL: %s\n" info.url;
  Printf.printf "Expires: %s\n" info.expires_at;
  Printf.printf "Size: %dx%d (%d bytes)\n" 
    info.width info.height info.size_bytes;
  Lwt.return_unit
| _ -> ...
```

### Getting Usage Statistics

```ocaml
let* result = Pxshot.get_usage client in
match result with
| Ok usage ->
  Printf.printf "Screenshots: %d/%d\n" 
    usage.screenshots_taken usage.screenshots_limit;
  Printf.printf "Storage: %d/%d bytes\n" 
    usage.bytes_used usage.bytes_limit;
  Lwt.return_unit
| Error e ->
  Printf.eprintf "Error: %s\n" (Pxshot.error_to_string e);
  Lwt.return_unit
```

### Error Handling

All API calls return `(result, error) result Lwt.t`. Error types:

```ocaml
type error =
  | Unauthorized of string   (* Invalid API key *)
  | BadRequest of string     (* Invalid parameters *)
  | RateLimited of string    (* Too many requests *)
  | ServerError of string    (* API server error *)
  | NetworkError of string   (* Connection issues *)
  | ParseError of string     (* Response parsing failed *)
```

Use `error_to_string` for human-readable messages:

```ocaml
match result with
| Error e -> Printf.eprintf "Failed: %s\n" (Pxshot.error_to_string e)
| Ok _ -> ...
```

## Types

### Format

```ocaml
type format = Png | Jpeg | Webp
```

### Wait Until

```ocaml
type wait_until = Load | Domcontentloaded | Networkidle
```

### Screenshot Response

```ocaml
type screenshot_response =
  | Bytes of bytes           (* Raw image data *)
  | Stored of stored_screenshot  (* URL and metadata *)

type stored_screenshot = {
  url : string;
  expires_at : string;
  width : int;
  height : int;
  size_bytes : int;
}
```

### Usage

```ocaml
type usage = {
  screenshots_taken : int;
  screenshots_limit : int;
  bytes_used : int;
  bytes_limit : int;
  period_start : string;
  period_end : string;
}
```

## Examples

See the [examples](./examples) directory:

- [`basic.ml`](./examples/basic.ml) - Simple screenshot to file
- [`stored.ml`](./examples/stored.ml) - Store and get URL
- [`usage.ml`](./examples/usage.ml) - Check usage statistics

Run examples:

```bash
PXSHOT_API_KEY=px_your_key dune exec examples/basic.exe
```

## Development

```bash
# Install dependencies
opam install . --deps-only --with-test

# Build
dune build

# Run tests
dune test

# Format code
dune fmt
```

## License

MIT - see [LICENSE](./LICENSE)

## Links

- [Pxshot Website](https://pxshot.com)
- [API Documentation](https://docs.pxshot.com)
- [GitHub](https://github.com/pxshot/pxshot-ocaml)
