{-# OPTIONS_GHC -Wno-unused-imports #-}
{-# LANGUAGE PatternSynonyms #-}
-- Copyright 2023 Lennart Augustsson
-- See LICENSE file for full license.
module MicroHs.Exp(
  Exp(..), toStringP,
  PrimOp,
  substExp,
  encodeString,
  app2, app3, cCons, cNil, cFlip,
  allVarsExp, freeVars,
  encodeList,
  ) where
import Prelude hiding((<>))
import Data.Char
import Data.List
import MicroHs.Ident
import MicroHs.Expr(Lit(..), showLit)
import Text.PrettyPrint.HughesPJ
import Control.DeepSeq
import Compat
import Debug.Trace

type PrimOp = String

data Exp
  = Var Ident
  | App Exp Exp
  | Lam Ident Exp
  | Lit Lit

instance Eq Exp where
  (==) (Var i1)    (Var i2)    = i1 == i2
  (==) (App f1 a1) (App f2 a2) = f1 == f2 && a1 == a2
  (==) (Lam i1 e1) (Lam i2 e2) = i1 == i2 && e1 == e2
  (==) (Lit l1)    (Lit l2)    = l1 == l2
  (==) _           _           = False

app2 :: Exp -> Exp -> Exp -> Exp
app2 f a1 a2 = App (App f a1) a2

app3 :: Exp -> Exp -> Exp -> Exp -> Exp
app3 f a1 a2 a3 = App (app2 f a1 a2) a3

cCons :: Exp
cCons = Lit (LPrim "O")

cNil :: Exp
cNil = Lit (LPrim "K")

cFlip :: Exp
cFlip = Lit (LPrim "C")

--cR :: Exp
--cR = Lit (LPrim "R")

-- Avoid quadratic concatenation by using difference lists,
-- turning concatenation into function composition.
toStringP :: Exp -> (String -> String)
toStringP ae =
  case ae of
    Var x   -> (showIdent x ++)
    Lit (LStr s) ->
      -- Encode very short string directly as combinators.
      if length s > 1 then
        (quoteString s ++)
      else
        toStringP (encodeString s)
    Lit (LInteger _) -> undefined
    Lit (LRat _) -> undefined
    Lit l   -> (showLit l ++)
    Lam x e -> (("(\\" ++ showIdent x ++ " ") ++) . toStringP e . (")" ++)
    App f a -> ("(" ++) . toStringP f . (" " ++) . toStringP a . (")" ++)

quoteString :: String -> String
quoteString s =
  let
    achar c =
      if c == '"' || c == '\\' || c < ' ' || c > '~' then
        '\\' : show (ord c) ++ ['&']
      else
        [c]
  in '"' : concatMap achar s ++ ['"']

encodeString :: String -> Exp
encodeString = encodeList . map (Lit . LInt . ord)

encodeList :: [Exp] -> Exp
encodeList = foldr (app2 cCons) cNil

instance Show Exp where
  show = render . ppExp

ppExp :: Exp -> Doc
ppExp ae =
  case ae of
--    Let i e b -> sep [ text "let" <+> ppIdent i <+> text "=" <+> ppExp e, text "in" <+> ppExp b ]
    Var i -> ppIdent i
    App f a -> parens $ ppExp f <+> ppExp a
    Lam i e -> parens $ text "\\" <> ppIdent i <> text "." <+> ppExp e
    Lit l -> text (showLit l)

substExp :: Ident -> Exp -> Exp -> Exp
substExp si se ae =
  case ae of
    Var i -> if i == si then se else ae
    App f a -> App (substExp si se f) (substExp si se a)
    Lam i e -> if si == i then
                 ae
               else if elem i (freeVars se) then
                 let
                   fe = allVarsExp e
                   ase = allVarsExp se
                   j = head [ v | n <- enumFrom (0::Int), let { v = mkIdent ("a" ++ show n) }, not (elem v ase), not (elem v fe) ]
                 in
                   --trace ("substExp " ++ unwords [si, i, j]) $
                   Lam j (substExp si se (substExp i (Var j) e))
               else
                   Lam i (substExp si se e)
    Lit _ -> ae

freeVars :: Exp -> [Ident]
freeVars ae =
  case ae of
    Var i -> [i]
    App f a -> freeVars f ++ freeVars a
    Lam i e -> deleteAllBy (==) i (freeVars e)
    Lit _ -> []

allVarsExp :: Exp -> [Ident]
allVarsExp ae =
  case ae of
    Var i -> [i]
    App f a -> allVarsExp f ++ allVarsExp a
    Lam i e -> i : allVarsExp e
    Lit _ -> []

--------
-- Possible additions
--
-- Added:
--  R = C C
--  R x y z = (C C x y) z = C y x z = y z x
--
--  Q = C I
--  Q x y z = (C I x y) z = I y x z = y x z
--
-- Added:
--  Z = B K
--  Z x y z = B K x y z = K (x y) z = x y
--
--  ZK = Z K
--  ZK x y z = Z K x y z = (K x) z = x
--
--  C'B = C' B
--  C'B x y z w = C' B x y z w = B (x z) y w = x z (y w)

--  B (B e) x y z = B e (x y) z = e (x y z)
--
--  B' :: (a -> b -> c) -> a -> (d -> b) -> d -> c
--  B' k f g x = k f (g x)
--
-- Common:
--  817: C' B
--  616: B Z
--  531: C' C
--  352: Z K
--  305: C' S
--
--  BZ = B Z
--  BZ x y z w = B Z x y z w = Z (x y) z w = x y z
--
--  C'C = C' C
--  C'C x y z w = C' C x y z w = C (x z) y w = x z w y


---------------------------------------------------------------

{-
-- Oleg's abstraction algorithm

data Peano = S Peano | Z
  deriving (Show)
data DB = N Peano | L DB | A DB DB | Free Ident | K Lit
  deriving (Show)

index :: Ident -> [Ident] -> Maybe Peano
index x xs = lookupBy eqIdent x $ zip xs $ iterate S Z

deBruijn :: Exp -> DB
deBruijn = go [] where
  go binds e =
    case e of
      Var x -> maybe (Free x) N $ index x binds
      App t u -> A (go binds t) (go binds u)
      Lam x t -> L $ go (x:binds) t
      Lit l -> K l

type CL = Exp
type BCL = ([Bool], CL)

com :: String -> Exp
com s = Lit (LPrim s)
(@@) :: Exp -> Exp -> Exp
(@@) f a = App f a

convertBool :: (BCL -> BCL -> CL) -> DB -> BCL
convertBool (#) ee =
  case ee of
    N Z -> (True:[], com "I")
    N (S e) -> (False:g, d) where (g, d) = rec $ N e
    L e -> case rec e of
             ([], d) -> ([], com "K" @@ d)
             (False:g, d) -> (g, ([], com "K") # (g, d))
             (True:g, d) -> (g, d)
    A e1 e2 -> (zipWithDefault False (||) g1 g2, t1 # t2) where
      t1@(g1, _) = rec e1
      t2@(g2, _) = rec e2
    Free s -> ([], Var s)
    K l -> ([], Lit l)
  where rec = convertBool (#)

optEta :: DB -> BCL
optEta = convertBool (#) where
  (#) ([], d1)           {- # -} ([],       d2)      = d1 @@ d2
  (#) ([], d1)           {- # -} (True:[],  Lit (LPrim "I")) = d1
  (#) ([], d1)           {- # -} (True:g2,  d2)      = ([], com "B" @@ d1) # (g2, d2)
  (#) ([], d1)           {- # -} (False:g2, d2)      = ([], d1) # (g2, d2)
  (#) (True:[], Lit (LPrim "I")) {- # -} ([],       d2)      = com "U" @@ d2
  (#) (True:[], Lit (LPrim "I")) {- # -} (False:g2, d2)      = ([], com "U") # (g2, d2)
  (#) (True:g1, d1)      {- # -} ([],       d2)      = ([], com "R" @@ d2) # (g1, d1)
  (#) (True:g1, d1)      {- # -} (True:g2,  d2)      = (g1, ([], com "S") # (g1, d1)) # (g2, d2)
  (#) (True:g1, d1)      {- # -} (False:g2, d2)      = (g1, ([], com "C") # (g1, d1)) # (g2, d2)
  (#) (False:g1, d1)     {- # -} ([],       d2)      = (g1, d1) # ([], d2)
  (#) (False:_g1, d1)    {- # -} (True:[],  Lit (LPrim "I")) = d1
  (#) (False:g1, d1)     {- # -} (True:g2,  d2)      = (g1, ([], com "B") # (g1, d1)) # (g2, d2)
  (#) (False:g1, d1)     {- # -} (False:g2, d2)      = (g1, d1) # (g2, d2)

zipWithDefault :: forall a b . a -> (a -> a -> b) -> [a] -> [a] -> [b]
zipWithDefault d f     []     ys = map (f d) ys
zipWithDefault d f     xs     [] = map (flip f d) xs
zipWithDefault d f (x:xt) (y:yt) = f x y : zipWithDefault d f xt yt

compileOptX :: Exp -> Exp
compileOptX = snd . optEta . deBruijn
-}

