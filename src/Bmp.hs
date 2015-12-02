{-# LANGUAGE TemplateHaskell, FlexibleInstances, IncoherentInstances#-}
module Bmp where

import Args
import Check
import Images
import Test.QuickCheck

import Data.Binary( Binary(..), encode )
import Codec.Picture.Bitmap
import Codec.Picture.Types
import Codec.Picture.Metadata

import qualified Data.ByteString.Lazy as L

import Data.DeriveTH
import DeriveArbitrary

import Data.Binary.Put( runPut )
import Data.List.Split

type BmpFile  = (BmpPalette, Image PixelRGBA8)  --(Metadatas, BmpPalette, Image PixelRGBA8) --(BmpHeader, BmpInfoHeader, BmpPalette, Image PixelRGBA8)

derive makeArbitrary ''BmpPalette
derive makeArbitrary ''BmpInfoHeader
derive makeArbitrary ''BmpHeader

derive makeShow ''BmpPalette
derive makeShow ''BmpHeader

encodeBMPFile :: BmpFile -> L.ByteString
--encodeBMPFile (hdr, info, pal, img) = runPut $ put hdr >> put info >> putPalette pal >> bmpEncode img
encodeBMPFile (pal,img) = encodeBitmapWithPalette pal img
mencode = encodeBMPFile

bmpmain (MainArgs _ cmd filename prop maxSuccess maxSize outdir b) = let (prog, args) = (head spl, tail spl) in
    (case prop of
        "zzuf" -> quickCheckWith stdArgs {chatty = not b, maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ zzufprop filename prog args mencode outdir)

        "radamsa" -> quickCheckWith stdArgs {chatty = not b, maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ radamprop filename prog args mencode outdir)

        "check" -> quickCheckWith stdArgs {chatty = not b, maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ checkprop filename prog args mencode outdir)
        "gen" -> quickCheckWith stdArgs {chatty = not b, maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ genprop filename prog args mencode outdir)
        "exec" -> quickCheckWith stdArgs {chatty = not b, maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ execprop filename prog args mencode outdir)
        _     -> error "Invalid action selected"
    ) where spl = splitOn " " cmd

main fargs False = bmpmain $ fargs ""
main fargs True  = processPar fargs bmpmain
