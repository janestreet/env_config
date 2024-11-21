module Stable = struct
  open Core.Core_stable

  module V1 = struct
    module Format = Async_log.Output.Format.Stable.V1

    type t =
      | Stdout
      | Stderr
      | File of
          { format : Format.t
          ; filename : string
          }
    [@@deriving sexp]
  end
end

open! Core
open Async_log
open Async_unix
include Stable.V1

let stdout = lazy (Output.writer `Sexp (force Writer.stdout))
let stderr = lazy (Output.writer `Sexp (force Writer.stderr))

let to_output = function
  | Stdout -> Lazy.force stdout
  | Stderr -> Lazy.force stderr
  | File { format; filename } -> Output.file format ~filename
;;
