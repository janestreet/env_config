open! Core
open Async_kernel

(** Configurations that are computed at runtime *)

module Blocking (Configuration : Configuration_intf.Embedded_in_library.Blocking) : sig
  (** Raises if [Configuration.environment_variable] is set to an invalid value or if
      getting the default [Configuration.t] raises. *)
  val get_config_exn : unit -> Configuration.t
end

module Blocking_overridable
    (Configuration : Configuration_intf.Embedded_in_library.Blocking_overridable) : sig
  (** Raises if [Configuration.environment_variable] is set to an invalid value or if
      getting the default [Configuration.t] raises. *)
  val get_config_exn : unit -> Configuration.t
end

module Async (Configuration : Configuration_intf.Embedded_in_library.Async) : sig
  (** Raises if [Configuration.environment_variable] is set to an invalid value or if
      getting the default [Configuration.t] raises. *)
  val get_config_exn : unit -> Configuration.t Deferred.t
end

module Async_overridable
    (Configuration : Configuration_intf.Embedded_in_library.Async_overridable) : sig
  (** Raises if [Configuration.environment_variable] is set to an invalid value or if
      getting the default [Configuration.t] raises. *)
  val get_config_exn : unit -> Configuration.t Deferred.t
end
