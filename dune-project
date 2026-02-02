(lang dune 3.0)

(name pxshot)

(version 0.1.2)

(generate_opam_files true)

(source
 (github faiscadev/pxshot-ocaml))

(authors "Pxshot <support@pxshot.com>")

(maintainers "Pxshot <support@pxshot.com>")

(license MIT)

(documentation https://docs.pxshot.com/sdks/ocaml)

(package
 (name pxshot)
 (synopsis "Official OCaml SDK for the Pxshot screenshot API")
 (description
  "A type-safe OCaml client for capturing screenshots via the Pxshot API. Supports configurable viewport sizes, full-page captures, various image formats, and cloud storage options.")
 (depends
  (ocaml (>= 4.14.0))
  (dune (>= 3.0))
  (cohttp-lwt-unix (>= 5.0.0))
  (lwt (>= 5.6.0))
  (yojson (>= 2.0.0))
  (uri (>= 4.0.0))
  (alcotest (and :with-test (>= 1.6.0)))
  (alcotest-lwt (and :with-test (>= 1.6.0))))
 (tags
  (screenshot api pxshot web-capture)))
