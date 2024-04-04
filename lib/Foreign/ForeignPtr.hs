module Foreign.ForeignPtr ( 
  ForeignPtr,
  FinalizerPtr,
  newForeignPtr,
  newForeignPtr_,
  addForeignPtrFinalizer,
  withForeignPtr,
  -- finalizeForeignPtr,
  touchForeignPtr,
  castForeignPtr,
  plusForeignPtr,
  mallocForeignPtr,
  mallocForeignPtrBytes,
  mallocForeignPtrArray,
  mallocForeignPtrArray0,
  ) where
import Primitives
import Foreign.Ptr
import Foreign.Storable
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array

instance Eq (ForeignPtr a) where
    p == q  =  unsafeForeignPtrToPtr p == unsafeForeignPtrToPtr q

{-
instance Ord (ForeignPtr a) where
    compare p q  =  compare (unsafeForeignPtrToPtr p) (unsafeForeignPtrToPtr q)
-}

instance Show (ForeignPtr a) where
    showsPrec p f = showsPrec p (unsafeForeignPtrToPtr f)

unsafeForeignPtrToPtr :: ForeignPtr a -> Ptr a
unsafeForeignPtrToPtr = primitive "fp2p"

type FinalizerPtr a = FunPtr (Ptr a -> IO ())

foreign import ccall "&free" c_freefun :: FinalizerPtr a

mallocForeignPtr :: Storable a => IO (ForeignPtr a)
mallocForeignPtr = do
  ptr <- malloc
  newForeignPtr c_freefun ptr

mallocForeignPtrBytes :: Int -> IO (ForeignPtr a)
mallocForeignPtrBytes size = do
  ptr <- mallocBytes size
  newForeignPtr c_freefun ptr

mallocForeignPtrArray :: Storable a => Int -> IO (ForeignPtr a)
mallocForeignPtrArray size = do
  ptr <- mallocArray size
  newForeignPtr c_freefun ptr

mallocForeignPtrArray0 :: Storable a => Int -> IO (ForeignPtr a)
mallocForeignPtrArray0 size = do
  ptr <- mallocArray0 size
  newForeignPtr c_freefun ptr

addForeignPtrFinalizer :: FinalizerPtr a -> ForeignPtr a -> IO ()
addForeignPtrFinalizer = primitive "fpfin"

newForeignPtr :: FinalizerPtr a -> Ptr a -> IO (ForeignPtr a)
newForeignPtr f p = do
  fp <- newForeignPtr_ p
  addForeignPtrFinalizer f fp
  return fp

newForeignPtr_ :: Ptr a -> IO (ForeignPtr a)
newForeignPtr_ = primitive "fpnew"

withForeignPtr :: ForeignPtr a -> (Ptr a -> IO b) -> IO b
withForeignPtr fp io = do
  b <- io (unsafeForeignPtrToPtr fp)
  touchForeignPtr fp
  return b

touchForeignPtr :: ForeignPtr a -> IO ()
touchForeignPtr fp = seq fp (return ())

castForeignPtr :: ForeignPtr a -> ForeignPtr b
castForeignPtr = primUnsafeCoerce

plusForeignPtr :: ForeignPtr a -> Int -> ForeignPtr b
plusForeignPtr = primitive "fp+"
