open Core

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
      ; override_parse_error : Error.t option
      ; documentation : string
      }
[@@deriving sexp_of]

let environment_value = function
  | Environment_variable_missing _ -> None
  | Environment_variable_present { environment_value; _ } -> Some environment_value
;;

let raise_exn ?extra_context t =
  let extra_context =
    match extra_context with
    | None -> ""
    | Some context -> context ^ "\n"
  in
  match t with
  | Environment_variable_missing
      { environment_variable; default_config_error; documentation } ->
    eprintf
      !{|
Unable to load default configuration for empty environment variable %S.

Config load error:
%{Error#hum}

%s
Documentation:
%s

|}
      environment_variable
      default_config_error
      extra_context
      documentation;
    raise_s [%message "Unable to parse configuration"]
  | Environment_variable_present
      { environment_value
      ; config_parse_error
      ; override_parse_error
      ; documentation
      ; environment_variable
      } ->
    let override_parse_error =
      match override_parse_error with
      | None -> ""
      | Some error -> sprintf !"Override parse error:\n%{Error#hum}\n" error
    in
    eprintf
      !{|
Unable to parse %S for environment variable %S


Config parse error:
%{Error#hum}

%s
%s
Documentation:
%s

|}
      environment_value
      environment_variable
      config_parse_error
      override_parse_error
      extra_context
      documentation;
    raise_s [%message "Unable to parse configuration"]
;;
