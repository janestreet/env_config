open! Core
open Async
open Expect_test_helpers_async

(** Instructions on how to start the test executable. *)
module Load_from_disk = struct
  type t =
    { save_default_configuration_to_disk : bool
    ; environment_override : [ `None | `String of string | `File ]
    (** [`None] : no environment override [`File] : environment override of file path with
        a valid configuration [`String str] : environment override of [str] *)
    }

  let default_config_path () =
    let%bind cwd = Unix.getcwd () in
    return (cwd ^/ "from_disk.sexp")
  ;;

  let prepare { save_default_configuration_to_disk; environment_override } ~temp_dir =
    let%bind () =
      if save_default_configuration_to_disk
      then (
        let%bind path = default_config_path () in
        Writer.save_sexp path (Sexp.of_string "Read_from_default_file"))
      else Deferred.unit
    in
    match environment_override with
    | `None -> return None
    | `String str -> return (Some str)
    | `File ->
      let temp_file = temp_dir ^/ "from_override.sexp" in
      let%bind () =
        Writer.save_sexp temp_file (Sexp.of_string "Read_from_environment_specified_file")
      in
      return (Some temp_file)
  ;;

  let cleanup { save_default_configuration_to_disk; _ } =
    if save_default_configuration_to_disk
    then (
      let%bind path = default_config_path () in
      Unix.remove path)
    else Deferred.unit
  ;;
end

let test ?blocking ?async ?(load_from_disk : Load_from_disk.t option) () =
  with_temp_dir (fun temp_dir ->
    let env var value = Option.map value ~f:(fun value -> var, value) |> Option.to_list in
    let%bind from_disk_environment =
      match load_from_disk with
      | None -> return []
      | Some load_from_disk ->
        let%bind value = Load_from_disk.prepare load_from_disk ~temp_dir in
        return (env "FROM_DISK_CFG" value)
    in
    let extend_env =
      [ env "BLOCKING" blocking; env "ASYNC" async; from_disk_environment ] |> List.concat
    in
    let%bind () =
      run
        ~extend_env
        "../example/example.exe"
        (if Option.is_some load_from_disk then [ "-load-from-disk" ] else [])
    in
    match load_from_disk with
    | None -> Deferred.unit
    | Some load_from_disk -> Load_from_disk.cleanup load_from_disk)
;;

let%expect_test "documentation" =
  let invalid = "invalid)" in
  let%bind () = test ~blocking:invalid ~async:invalid () in
  [%expect
    {|
     ("Unclean exit" (Exit_non_zero 1))
     --- STDERR ---

     Unable to parse "invalid)" for environment variable "BLOCKING"


     Config parse error:
     (Sexplib.Sexp.Parse_error
      ((err_msg "unexpected character: ')'") (text_line 1) (text_char 7)
       (global_offset 7) (buf_pos 7)))

     Override parse error:
     (Sexplib.Sexp.Parse_error
      ((err_msg "unexpected character: ')'") (text_line 1) (text_char 7)
       (global_offset 7) (buf_pos 7)))


     Documentation:
     Use '(This_car STR)' to override the default car. See lib/env_config/example.ml for a full configuration description.

     (monitor.ml.Error "Unable to parse configuration")
     |}];
  return ()
;;

let%expect_test "defaults" =
  let%bind () = test () in
  [%expect
    {|
     Blocking: ((car"Ford Model T")(phrase"Gee, Brain, what do you want to do tonight?"))
     Simple: ()
     Async: (Other fuscia)
     |}];
  return ()
;;

let%expect_test "user overrides" =
  let%bind () = test ~blocking:{|(This_car "Porsche Cayman")|} ~async:"Invert" () in
  [%expect
    {|
     Blocking: ((car"Porsche Cayman")(phrase"Gee, Brain, what do you want to do tonight?"))
     Simple: ()
     Async: (Other aicsuf)
     |}];
  return ()
;;

let%expect_test "full configs" =
  let%bind () = test ~blocking:{|((car none)(phrase "know thyself"))|} ~async:"Red" () in
  [%expect
    {|
     Blocking: ((car none)(phrase"know thyself"))
     Simple: ()
     Async: Red
     |}];
  return ()
;;

let%expect_test "config is on disk, no environment" =
  let load_from_disk =
    { Load_from_disk.save_default_configuration_to_disk = true
    ; environment_override = `None
    }
  in
  let%bind () = test ~load_from_disk () in
  [%expect
    {|
     Blocking: ((car"Ford Model T")(phrase"Gee, Brain, what do you want to do tonight?"))
     Simple: ()
     Async: (Other fuscia)
     From Disk: Read_from_default_file
     |}];
  return ()
;;

let%expect_test "config is on disk, filename in environment" =
  let load_from_disk =
    { Load_from_disk.save_default_configuration_to_disk = true
    ; environment_override = `File
    }
  in
  let%bind () = test ~load_from_disk () in
  [%expect
    {|
     Blocking: ((car"Ford Model T")(phrase"Gee, Brain, what do you want to do tonight?"))
     Simple: ()
     Async: (Other fuscia)
     From Disk: Read_from_environment_specified_file
     |}];
  return ()
;;

let%expect_test "config is on disk, environment override parses (not a file)" =
  let load_from_disk =
    { Load_from_disk.save_default_configuration_to_disk = true
    ; environment_override = `String "()"
    }
  in
  let%bind () = test ~load_from_disk () in
  [%expect
    {|
     Blocking: ((car"Ford Model T")(phrase"Gee, Brain, what do you want to do tonight?"))
     Simple: ()
     Async: (Other fuscia)
     From Disk: (Environment_override(Ok()))
     |}];
  return ()
;;

let%expect_test "config is on disk, environment override doesn't parse (not a file)" =
  let load_from_disk =
    { Load_from_disk.save_default_configuration_to_disk = true
    ; environment_override = `String ")"
    }
  in
  let%bind () = test ~load_from_disk () in
  [%expect
    {|
     Blocking: ((car"Ford Model T")(phrase"Gee, Brain, what do you want to do tonight?"))
     Simple: ()
     Async: (Other fuscia)
     ("Unclean exit" (Exit_non_zero 1))
     --- STDERR ---

     Unable to parse ")" for environment variable "FROM_DISK_CFG"


     Config parse error:
     (Sexplib.Sexp.Parse_error
      ((err_msg "unexpected character: ')'") (text_line 1) (text_char 0)
       (global_offset 0) (buf_pos 0)))

     Override parse error:
     (Sexplib.Sexp.Parse_error
      ((err_msg "unexpected character: ')'") (text_line 1) (text_char 0)
       (global_offset 0) (buf_pos 0)))

     File parsing error: environment value is not a file path

     Documentation:

     An override of () will result in the config using [Environment_override].

     (monitor.ml.Error "Unable to parse configuration")
     |}];
  return ()
;;

let%expect_test "config on not on disk, filename in environment" =
  let load_from_disk =
    { Load_from_disk.save_default_configuration_to_disk = false
    ; environment_override = `File
    }
  in
  let%bind () = test ~load_from_disk () in
  [%expect
    {|
     Blocking: ((car"Ford Model T")(phrase"Gee, Brain, what do you want to do tonight?"))
     Simple: ()
     Async: (Other fuscia)
     From Disk: Read_from_environment_specified_file
     |}];
  return ()
;;

let%expect_test "config on not on disk, environment override parses (not a file)" =
  let load_from_disk =
    { Load_from_disk.save_default_configuration_to_disk = false
    ; environment_override = `String "()"
    }
  in
  let%bind () = test ~load_from_disk () in
  Expect_test_patterns.require_match
    {|
    Blocking: ((car"Ford Model T")(phrase"Gee, Brain, what do you want to do tonight?"))
    Simple: ()
    Async: (Other fuscia)
    From Disk: (Environment_override(Error(monitor.ml.Error(Unix.Unix_error"No such file or directory"open"*")))) (glob) |};
  return ()
;;
