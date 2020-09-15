open Core

module Gen (Configuration : Configuration_intf.S) = struct
  include Deserializers.Make (Configuration)

  let from_env_result ~default_config ~from_override =
    match Sys.getenv Configuration.environment_variable with
    | None ->
      default_config
      |> Result.map_error ~f:(fun default_config_error ->
        Could_not_load.Environment_variable_missing
          { environment_variable = Configuration.environment_variable
          ; documentation = Configuration.documentation
          ; default_config_error
          })
    | Some value ->
      (match deserialize [%of_sexp: Configuration.t] value with
       | Ok v -> Ok v
       | Error config_parse_error ->
         let error override_parse_error =
           Error
             (Could_not_load.Environment_variable_present
                { environment_value = value
                ; environment_variable = Configuration.environment_variable
                ; config_parse_error
                ; override_parse_error
                ; documentation = Configuration.documentation
                })
         in
         (match from_override with
          | None -> error None
          | Some (of_sexp, from_override) ->
            (match deserialize of_sexp value with
             | Ok x -> Ok (from_override ~default_config x)
             | Error override_parse_error -> error (Some override_parse_error))))
  ;;

  let from_env_exn ~default_config ~from_override =
    match from_env_result ~default_config ~from_override with
    | Ok x -> x
    | Error cnl -> Could_not_load.raise_exn cnl
  ;;
end

module Make (Configuration : Configuration_intf.S) = struct
  include Gen (Configuration)

  let from_env_result = from_env_result ~from_override:None
  let from_env_exn = from_env_exn ~from_override:None
end

module Make_overridable (Configuration : Configuration_intf.Overridable) = struct
  include Gen (Configuration)

  let from_override =
    ([%of_sexp: Configuration.Environment_override.t], Configuration.from_override)
    |> Option.return
  ;;

  let from_env_result = from_env_result ~from_override
  let from_env_exn = from_env_exn ~from_override
end
