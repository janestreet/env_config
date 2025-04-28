open! Core
open Async_kernel

(** Configurations that are loaded from a file on disk.

    If the configuration cannot be parsed via [Load_from_environment], and the
    Configuration's environment value is a file, that file will be loaded and used as the
    configuration. *)

module Blocking (Configuration : Configuration_intf.Load_from_disk.Blocking) : sig
  (** Raises if [Configuration.environment_variable] is set to an invalid value or if
      getting the default [Configuration.t] raises. *)
  val get_config_exn : unit -> Configuration.t
end

module Blocking_overridable
    (Configuration : Configuration_intf.Load_from_disk.Blocking_overridable) : sig
  (** Raises if [Configuration.environment_variable] is set to an invalid value or if
      getting the default [Configuration.t] raises. *)
  val get_config_exn : unit -> Configuration.t
end

module Async (Configuration : Configuration_intf.Load_from_disk.Async) : sig
  (** Raises if [Configuration.environment_variable] is set to an invalid value or if
      getting the default [Configuration.t] raises. *)
  val get_config_exn : unit -> Configuration.t Deferred.t
end

module Async_overridable
    (Configuration : Configuration_intf.Load_from_disk.Async_overridable) : sig
  (** Raises if [Configuration.environment_variable] is set to an invalid value or if
      getting the default [Configuration.t] raises. *)
  val get_config_exn : unit -> Configuration.t Deferred.t
end
