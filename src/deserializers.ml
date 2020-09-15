open! Core

module Make (Configuration : Configuration_intf.S) = struct
  let safe_t_of_sexp =
    if Configuration.allow_extra_fields
    then Sexp.of_sexp_allow_extra_fields_recursively
    else Fn.id
  ;;

  let deserialize t_of_sexp x =
    Or_error.try_with (fun () -> safe_t_of_sexp t_of_sexp (Sexp.of_string x))
  ;;
end
