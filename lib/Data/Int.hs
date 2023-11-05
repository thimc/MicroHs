-- Copyright 2023 Lennart Augustsson
-- See LICENSE file for full license.
module Data.Int(module Data.Int, Int) where
import Primitives
import Data.Bool_Type
import Data.Bounded
import Data.Char_Type
import Data.Eq
import Data.Integer_Type
import Data.Integral
import Data.List_Type
import Data.Num
import Data.Ord
import Data.Ratio_Type
import Data.Real
import Text.Show

instance Num Int where
  (+)  = primIntAdd
  (-)  = primIntSub
  (*)  = primIntMul
  negate x = primIntNeg x
  abs x = if x < 0 then negate x else x
  signum x =
    case compare x 0 of
      LT -> -1
      EQ ->  0
      GT ->  1
  fromInteger = _integerToInt

instance Integral Int where
  quot = primIntQuot
  rem  = primIntRem
  toInteger = _intToInteger

instance Bounded Int where
  minBound = primWordToInt ((-1::Word) `primWordQuot` 2) + 1
  maxBound = primWordToInt ((-1::Word) `primWordQuot` 2)

instance Real Int where
  toRational i = _integerToRational (_intToInteger i)

--------------------------------

instance Eq Int where
  (==) = primIntEQ
  (/=) = primIntNE

instance Ord Int where
  (<)  = primIntLT
  (<=) = primIntLE
  (>)  = primIntGT
  (>=) = primIntGE

--------------------------------

instance Show Int where
  show = showInt_

-- XXX these should not be exported
-- XXX wrong for minInt
showInt_ :: Int -> String
showInt_ n =
  if n < 0 then
    '-' : _showUnsignedNegInt n
  else
    _showUnsignedNegInt (negate n)

-- Some trickery to show minBound correctly.
-- To print the number n, pass -n.
_showUnsignedNegInt :: Int -> String
_showUnsignedNegInt n =
  let
    c = primChr (primOrd '0' - rem n 10)
  in  if n > -10 then
        [c]
      else
        _showUnsignedNegInt (quot n 10) ++ [c]
