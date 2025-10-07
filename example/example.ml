open Core

(** This executable demonstrates usage of [Env_config]. Its sole purpose is to print out
    what configuration it believes it should have, e.g.

    $ EXAMPLE_CONFIG='(This_car "Porsche Cayman")' ./example.exe ((car "Porsche Cayman")
    (phrase "Gee, Brain, what do you want to do tonight?"))

    See the lib/env_config/test subdirectory for more example invocations. *)

let () = Backtrace.Exn.set_recording false

module Blocking = struct
  (** The library/app configuration *)
  module Config = struct
    type t =
      { car : string
      ; phrase : string
      }
    [@@deriving sexp]
  end

  (** Used for retrieving the config *)
  module Get_config = Env_config.Embedded_in_library.Blocking_overridable (struct
      include Config

      let default () =
        { car = "Ford Model T"; phrase = "Gee, Brain, what do you want to do tonight?" }
      ;;

      module Environment_override = struct
        type t = This_car of string [@@deriving sexp]
      end

      let environment_variable = "BLOCKING"

      let from_override ~default_config (Environment_override.This_car car) =
        let { phrase; _ } = Or_error.ok_exn default_config in
        { car; phrase }
      ;;

      let documentation =
        "Use '(This_car STR)' to override the default car. See lib/env_config/example.ml \
         for a full configuration description."
      ;;

      let allow_extra_fields = false
    end)
end

module Asynchronous = struct
  (** The library/app configuration *)
  module Config = struct
    type t =
      | Red
      | Green
      | Other of string
    [@@deriving sexp]
  end

  (** Used for retrieving the config *)
  module Get_config = Env_config.Embedded_in_library.Async_overridable (struct
      open Async
      include Config

      let default () = return @@ Other "fuscia"

      module Environment_override = struct
        type t = Invert [@@deriving sexp]
      end

      let environment_variable = "ASYNC"

      let from_override ~default_config Environment_override.Invert =
        match Or_error.ok_exn default_config with
        | Other x -> Other (String.rev x)
        | Green -> Red
        | Red -> Green
      ;;

      let documentation =
        "Use 'Invert' to invert red to green (and vice versa.) Other x will have x \
         reversed. See lib/env_config/example.ml for a full configuration description."
      ;;

      let allow_extra_fields = false
    end)
end

(* As simple as possible *)
module Simple = Env_config.Embedded_in_library.Blocking (struct
    type t = unit [@@deriving sexp]

    let default () = ()
    let documentation = ""
    let allow_extra_fields = false
    let environment_variable = "SIMPLE"
  end)

module From_disk = struct
  module Config = struct
    type t =
      | Environment_override of unit Or_error.t
      | Read_from_default_file
      | Read_from_environment_specified_file
    [@@deriving sexp]
  end

  include Env_config.Load_from_disk.Async_overridable (struct
      include Config

      module Environment_override = struct
        type t = unit [@@deriving sexp]
      end

      let default_path () =
        let open Async in
        let%map cwd = Unix.getcwd () in
        cwd ^/ "from_disk.sexp"
      ;;

      let from_override ~default_config () =
        default_config |> Or_error.map ~f:(const ()) |> Environment_override
      ;;

      let documentation =
        {|
An override of () will result in the config using [Environment_override]. |}
      ;;

      let load_from_disk ~path =
        let open Async in
        Reader.load_sexp_exn path [%of_sexp: t]
      ;;

      let allow_extra_fields = false
      let environment_variable = "FROM_DISK_CFG"
    end)
end

let () =
  let open Async in
  Command.async
    ~summary:"Print out a configuration to demonstrate an environment override"
    (let open Command.Let_syntax in
     let%map_open load_from_disk =
       flag "load-from-disk" no_arg ~doc:" run the load from disk code"
     in
     fun () ->
       let open Deferred.Let_syntax in
       Blocking.Get_config.get_config_exn ()
       |> printf !"Blocking: %{sexp#mach:Blocking.Config.t}\n";
       Simple.get_config_exn () |> printf !"Simple: %{sexp:unit}\n";
       let%bind () =
         Asynchronous.Get_config.get_config_exn ()
         >>| printf !"Async: %{sexp#mach:Asynchronous.Config.t}\n"
       in
       let%bind () =
         if load_from_disk
         then
           From_disk.get_config_exn ()
           >>| printf !"From Disk: %{sexp#mach:From_disk.Config.t}\n"
         else Deferred.unit
       in
       Deferred.unit)
    ~behave_nicely_in_pipeline:false
  |> Command_unix.run
;;
