open! Core
open Async
module Format = Async.Log.Output.Format.Stable.V1

type t =
  | Stdout
  | Stderr
  | File of
      { format : Format.t
      ; filename : string
      }
[@@deriving sexp_of]

val to_output : t -> Log.Output.t

module Stable : sig
  module V1 : sig
    type nonrec t = t [@@deriving sexp]
  end
end
