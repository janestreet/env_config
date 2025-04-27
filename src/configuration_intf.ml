open! Core
open Async_kernel

module type S = sig
  (** Some configuration that a program wants *)
  type t [@@deriving of_sexp]

  (** The environment variable used to retrieve configuration overrides *)
  val environment_variable : string

  (** What to display when the environment variable is malformed, in addition to some
      helpful information *)
  val documentation : string

  (** Allow extra fields to be present in the configuration sexp deserializer. Most users
      will want this to be true, as it is unlikely the configuration will always be the
      same type, and most types are not versioned. *)
  val allow_extra_fields : bool
end

module type Overridable = sig
  include S

  (** A mechanism for instructing a different configuration than the default be loaded by
      providing a different environment value than a [t].

      This is used, for example, to modify a particular part of a [t] without having to
      specify all of it. *)
  module Environment_override : sig
    type t [@@deriving of_sexp]
  end

  (** The environment requested that the config be determined by [Environment_override].
      The default is provided to this function. *)
  val from_override : default_config:t Or_error.t -> Environment_override.t -> t
end

(** The default configuration is loaded from a file on disk. *)
module Load_from_disk = struct
  (** The default path, and loading function are computed synchronously *)
  module type Blocking = sig
    type t

    include S with type t := t

    (** The default configuration *)
    val default_path : unit -> string

    (** How to load a configuration from disk. This will be used in conjunction with
        [default_path] if no override is provided. *)
    val load_from_disk : path:string -> t
  end

  module type Blocking_overridable = sig
    include Blocking
    include Overridable with type t := t
  end

  (** The default path, and loading function are computed asynchronously *)
  module type Async = sig
    type t

    include S with type t := t

    (** The default configuration *)
    val default_path : unit -> string Deferred.t

    (** How to load a configuration from disk. This will be used in conjunction with
        [default_path] if no override is provided. *)
    val load_from_disk : path:string -> t Deferred.t
  end

  module type Async_overridable = sig
    include Async
    include Overridable with type t := t
  end
end

(** The default configuration is computed, or embedded in the library *)
module Embedded_in_library = struct
  (** The default configuration is computed synchronously *)
  module type Blocking = sig
    type t

    include S with type t := t

    (** Compute the default configuration *)
    val default : unit -> t
  end

  module type Blocking_overridable = sig
    include Blocking
    include Overridable with type t := t
  end

  (** The default configuration is computed asynchronously *)
  module type Async = sig
    type t

    include S with type t := t

    (** Compute the default configuration *)
    val default : unit -> t Deferred.t
  end

  module type Async_overridable = sig
    include Async
    include Overridable with type t := t
  end
end
