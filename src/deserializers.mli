open! Core

module Make (Configuration : Configuration_intf.S) : sig
  val safe_t_of_sexp : (Sexp.t -> 'a) -> Sexp.t -> 'a
  val deserialize : (Sexp.t -> 'a) -> string -> 'a Or_error.t
end
