module Infix(main) where
import Prelude

infix 1 ===
infixl 2 +++
infixr 3 &&&

(===) :: Int -> Int -> Bool
x === y = x == y+1

(+++) :: Int -> Int -> Int
a +++ b = a + b + 1

(&&&) :: Int -> Int -> Int
a &&& b = a * (b + 1)

main :: IO ()
main = do
  putStrLn $ show $ 2 +++ 3 &&& 4 === 17
