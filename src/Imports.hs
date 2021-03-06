{-# LANGUAGE NoImplicitPrelude #-}


{- |
Imports used in the whole codebase. (All modules import this one instead of
the "Prelude".)
-}
module Imports
(
  module X,
  LByteString,
  LText,
)
where


import           BasePrelude            as X
  hiding (Category, GeneralCategory, lazy, Handler, diff, option)
-- Conversions
import           To                     as X
-- Lists
import           Data.List.Extra        as X (dropEnd, takeEnd)
import           Data.List.Index        as X
-- Lenses
import           Lens.Micro.Platform    as X
-- Monads and monad transformers
import           Control.Monad.Reader   as X
import           Control.Monad.State    as X
import           Control.Monad.Except   as X
-- Common types
import           Data.ByteString        as X (ByteString)
import           Data.Map               as X (Map)
import           Data.Set               as X (Set)
import           Data.Text              as X (Text)
-- Time
import           Data.Time              as X
-- Files
import           System.Directory       as X
import           System.FilePath        as X
-- Deepseq
import           Control.DeepSeq        as X
-- Hashable
import           Data.Hashable          as X
-- Lazy
import qualified Data.ByteString.Lazy   as BSL
import qualified Data.Text.Lazy         as TL
-- Formatting
import           Fmt                    as X


type LByteString = BSL.ByteString
type LText = TL.Text
