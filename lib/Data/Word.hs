-- Copyright 2023 Lennart Augustsson
-- See LICENSE file for full license.
module Data.Word(module Data.Word, Word) where
import Primitives
import Data.Bool_Type
import qualified Data.Char as C
import Data.Eq
import Data.Int()  -- insances only
import Data.List
import Data.Num
import Text.Show

infixl 7 `quot`,`rem`

instance Num Word where
  (+)  = primWordAdd
  (-)  = primWordSub
  (*)  = primWordMul
  abs x = x
  signum x = if x == fromInt 0 then fromInt 0 else fromInt 1
  fromInt = primUnsafeCoerce

{-
-- Arithmetic
(+) :: Word -> Word -> Word
(+)  = primWordAdd
(-) :: Word -> Word -> Word
(-)  = primWordSub
(*) :: Word -> Word -> Word
(*)  = primWordMul
-}

quot :: Word -> Word -> Word
quot = primWordQuot
rem :: Word -> Word -> Word
rem  = primWordRem

--------------------------------

--infix 4 ==,/=
infix 4 <,<=,>,>=

{-
-- Comparison
(==) :: Word -> Word -> Bool
(==) = primWordEQ
(/=) :: Word -> Word -> Bool
(/=) = primWordNE
-}

instance Eq Word where
  (==) = primWordEQ
  (/=) = primWordNE

(<)  :: Word -> Word -> Bool
(<)  = primWordLT
(<=) :: Word -> Word -> Bool
(<=) = primWordLE
(>)  :: Word -> Word -> Bool
(>)  = primWordGT
(>=) :: Word -> Word -> Bool
(>=) = primWordGE

eqWord :: Word -> Word -> Bool
eqWord = (==)

intToWord :: Int -> Word
intToWord = primUnsafeCoerce

wordToInt :: Word -> Int
wordToInt = primUnsafeCoerce

--------------------------------

instance Show Word where
  show = showWord
    where
      showWord :: Word -> C.String
      showWord n =
        let
          c = C.chr ((+) (C.ord '0') (wordToInt (rem n (intToWord 10))))
        in  case n < intToWord 10 of
              False -> showWord (quot n (intToWord 10)) ++ [c]
              True  -> [c]
