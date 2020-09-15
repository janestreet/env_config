module Stable = struct
  open Core.Core_stable

  module V1 = struct
    module Format = Async.Log.Output.Format.Stable.V1

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

open Core
open Async
include Stable.V1

let stdout = lazy (Log.Output.writer `Sexp (force Writer.stdout))
let stderr = lazy (Log.Output.writer `Sexp (force Writer.stderr))

let to_output = function
  | Stdout -> Lazy.force stdout
  | Stderr -> Lazy.force stderr
  | File { format; filename } -> Log.Output.file format ~filename
;;
