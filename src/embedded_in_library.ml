open! Core

module Blocking (Configuration : Configuration_intf.Embedded_in_library.Blocking) = struct
  include Load_from_environment.Make (Configuration)

  let get_config_exn () =
    let default_config = Or_error.try_with (fun () -> Configuration.default ()) in
    from_env_exn ~default_config
  ;;
end

module Blocking_overridable
    (Configuration : Configuration_intf.Embedded_in_library.Blocking_overridable) =
struct
  include Load_from_environment.Make_overridable (Configuration)

  let get_config_exn () =
    let default_config = Or_error.try_with (fun () -> Configuration.default ()) in
    from_env_exn ~default_config
  ;;
end

module Async_overridable
    (Configuration : Configuration_intf.Embedded_in_library.Async_overridable) =
struct
  open Async_kernel
  include Load_from_environment.Make_overridable (Configuration)

  let get_config_exn () =
    let%map default_config =
      Deferred.Or_error.try_with ~run:`Schedule ~rest:`Log (fun () ->
        Configuration.default ())
    in
    from_env_exn ~default_config
  ;;
end

module Async (Configuration : Configuration_intf.Embedded_in_library.Async) = struct
  open Async_kernel
  include Load_from_environment.Make (Configuration)

  let get_config_exn () =
    let%map default_config =
      Deferred.Or_error.try_with ~run:`Schedule ~rest:`Log (fun () ->
        Configuration.default ())
    in
    from_env_exn ~default_config
  ;;
end
