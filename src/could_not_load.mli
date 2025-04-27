open Core

(** Represents a failure to retrieve a config from the environment or default config *)

type t =
  | Environment_variable_missing of
      { environment_variable : string
      ; default_config_error : Error.t
      ; documentation : string
      }
  | Environment_variable_present of
      { environment_value : string
      ; environment_variable : string
      ; config_parse_error : Error.t
      ; override_parse_error : Error.t option (* Not every functor supports overrides *)
      ; documentation : string
      }
[@@deriving sexp_of]

(** The value that was read from the environment *)
val environment_value : t -> string option

(** [raise_exn ?extra_context t] will raise an exception, and print to stderr a
    description of why parsing failed, [extra_context], as well as documentation. *)
val raise_exn : ?extra_context:string -> t -> 'a
