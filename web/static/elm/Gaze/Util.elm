module Gaze.Util where

chunk2 : List a -> List (List a)
chunk2 list =
  case list of
    x :: y :: rest ->
      [x, y] :: chunk2 rest
    _ ->
      []

zip : List a -> List b -> List (a, b)
zip xs ys =
  case (xs, ys) of
    (x :: xs', y :: ys') ->
      (x, y) :: zip xs' ys'
    _ ->
      []

zipDefault : b -> List a -> List b -> List (a, b)
zipDefault default xs ys =
  case (xs, ys) of
    (x :: xs', y :: ys') ->
      (x, y) :: zipDefault default xs' ys'
    (x :: xs', []) ->
      (x, default) :: zipDefault default xs' []
    _ ->
      []
