open! Core
open Async_log_kernel
module Format = Output.Format.Stable.V1

type t =
  | Stdout
  | Stderr
  | File of
      { format : Format.t
      ; filename : string
      }
[@@deriving sexp_of]

val to_output : t -> Output.t

module Stable : sig
  module V1 : sig
    type nonrec t = t [@@deriving sexp]
  end
end
