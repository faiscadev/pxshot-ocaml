(** Pxshot - Official OCaml SDK for the Pxshot screenshot API *)

(** {1 Types} *)

(** Image format for screenshots *)
type format =
  | Png
  | Jpeg
  | Webp

(** Wait condition for page loading *)
type wait_until =
  | Load
  | Domcontentloaded
  | Networkidle

(** Screenshot options *)
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
}

(** Result when store=true *)
type stored_screenshot = {
  url : string;
  expires_at : string;
  width : int;
  height : int;
  size_bytes : int;
}

(** Screenshot response - either raw bytes or stored URL *)
type screenshot_response =
  | Bytes of bytes
  | Stored of stored_screenshot

(** Usage statistics *)
type usage = {
  screenshots_taken : int;
  screenshots_limit : int;
  bytes_used : int;
  bytes_limit : int;
  period_start : string;
  period_end : string;
}

(** Error types *)
type error =
  | Unauthorized of string
  | BadRequest of string
  | RateLimited of string
  | ServerError of string
  | NetworkError of string
  | ParseError of string

(** {1 Client} *)

(** The Pxshot client *)
type t

(** Create a new Pxshot client with the given API key.
    @param base_url Optional custom API base URL (defaults to https://api.pxshot.com) *)
val create : ?base_url:string -> string -> t

(** {1 Screenshot} *)

(** Capture a screenshot of the given URL.
    
    @param url The URL to capture
    @param format Image format (default: Png)
    @param quality JPEG/WebP quality 1-100 (default: 80)
    @param width Viewport width in pixels (default: 1280)
    @param height Viewport height in pixels (default: 720)
    @param full_page Capture the full scrollable page (default: false)
    @param wait_until Wait condition (default: Load)
    @param wait_for_selector CSS selector to wait for before capture
    @param wait_for_timeout Additional wait time in milliseconds
    @param device_scale_factor Device scale factor for retina displays (default: 1.0)
    @param store Store screenshot and return URL instead of bytes (default: false)
    
    @return Screenshot bytes or stored URL info *)
val screenshot :
  t ->
  url:string ->
  ?format:format ->
  ?quality:int ->
  ?width:int ->
  ?height:int ->
  ?full_page:bool ->
  ?wait_until:wait_until ->
  ?wait_for_selector:string ->
  ?wait_for_timeout:int ->
  ?device_scale_factor:float ->
  ?store:bool ->
  unit ->
  (screenshot_response, error) result Lwt.t

(** {1 Usage} *)

(** Get current usage statistics *)
val get_usage : t -> (usage, error) result Lwt.t

(** {1 Helpers} *)

(** Convert format to string *)
val format_to_string : format -> string

(** Convert wait_until to string *)
val wait_until_to_string : wait_until -> string

(** Convert error to human-readable string *)
val error_to_string : error -> string
