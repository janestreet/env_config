(** These modules are used to generate a function that can load a configuration from the
    environment. *)
open Core

module Make (C : Configuration_intf.S) : sig
  (** [from_env_exn ~default] will:
      + return [default] if [C.environment_variable] is not set
      + raises if [C.environment_variable] can't be parsed into a [C.t] or
        [C.Environment_override.t] *)
  val from_env_exn : default_config:C.t Or_error.t -> C.t

  val from_env_result : default_config:C.t Or_error.t -> (C.t, Could_not_load.t) Result.t
end

module Make_overridable (C : Configuration_intf.Overridable) : sig
  (** [from_env_exn ~default] will do everything that [Required.from_env_exn] will do,
      except that it will return [t] if [C.environment_variable] deserializes to [t] via a
      [C.Environment_override.t]. *)
  val from_env_exn : default_config:C.t Or_error.t -> C.t

  val from_env_result : default_config:C.t Or_error.t -> (C.t, Could_not_load.t) Result.t
end
