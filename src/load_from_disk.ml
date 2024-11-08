open! Core

let invalid ?extra_context could_not_load =
  let extra_context =
    Option.map extra_context ~f:(fun extra_context ->
      "File parsing error: " ^ extra_context)
  in
  Could_not_load.raise_exn ?extra_context could_not_load
;;

module Make_blocking (Configuration : sig
    include Configuration_intf.Load_from_disk.Blocking

    val from_env_result : default_config:t Or_error.t -> (t, Could_not_load.t) Result.t
  end) =
struct
  include Deserializers.Make (Configuration)

  let get_config_exn () =
    let default_config =
      Or_error.try_with (fun () ->
        Configuration.load_from_disk ~path:(Configuration.default_path ()))
    in
    match Configuration.from_env_result ~default_config with
    | Ok x -> x
    | Error cnl ->
      (match Could_not_load.environment_value cnl with
       | None -> invalid cnl
       | Some environment_value ->
         (match Sys_unix.file_exists environment_value with
          | `No | `Unknown ->
            invalid cnl ~extra_context:"environment value is not a file path"
          | `Yes ->
            (match
               Or_error.try_with (fun () ->
                 Sexp.load_sexp environment_value
                 |> safe_t_of_sexp [%of_sexp: Configuration.t])
             with
             | Ok x -> x
             | Error e -> invalid cnl ~extra_context:(Error.to_string_mach e))))
  ;;
end

module Blocking (Configuration : Configuration_intf.Load_from_disk.Blocking) = struct
  include Make_blocking (struct
      include Configuration
      include Load_from_environment.Make (Configuration)
    end)
end

module Blocking_overridable
    (Configuration : Configuration_intf.Load_from_disk.Blocking_overridable) =
struct
  include Make_blocking (struct
      include Configuration
      include Load_from_environment.Make_overridable (Configuration)
    end)
end

module Make_async (Configuration : sig
    include Configuration_intf.Load_from_disk.Async

    val from_env_result : default_config:t Or_error.t -> (t, Could_not_load.t) Result.t
  end) =
struct
  open Async_kernel
  open Async_unix
  include Deserializers.Make (Configuration)

  let get_config_exn () =
    let%bind default_config =
      Deferred.Or_error.try_with ~run:`Schedule ~rest:`Log (fun () ->
        let%bind path = Configuration.default_path () in
        Configuration.load_from_disk ~path)
    in
    match Configuration.from_env_result ~default_config with
    | Ok x -> return x
    | Error cnl ->
      (match Could_not_load.environment_value cnl with
       | None -> invalid cnl
       | Some maybe_path ->
         (match%bind Sys.file_exists maybe_path with
          | `No | `Unknown ->
            invalid cnl ~extra_context:"environment value is not a file path"
          | `Yes ->
            (match%map
               Reader.load_sexp maybe_path (safe_t_of_sexp [%of_sexp: Configuration.t])
             with
             | Ok x -> x
             | Error e -> invalid cnl ~extra_context:(Error.to_string_mach e))))
  ;;
end

module Async (Configuration : Configuration_intf.Load_from_disk.Async) = struct
  include Make_async (struct
      include Configuration
      include Load_from_environment.Make (Configuration)
    end)
end

module Async_overridable
    (Configuration : Configuration_intf.Load_from_disk.Async_overridable) =
struct
  include Make_async (struct
      include Configuration
      include Load_from_environment.Make_overridable (Configuration)
    end)
end
