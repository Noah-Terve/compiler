(lang dune 3.7)

(name toplevel)

(generate_opam_files true)

(source
 (github Noah-Terve/compiler))

(authors "Haijun Si" "Noah Tervelon" "Christopher Sasanuma" "Neil Powers")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name toplevel)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune)
 (tags
  (topics "to describe" your project)))

(using menhir 2.0)

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
