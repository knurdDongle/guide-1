{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE OverloadedStrings     #-}


{-# OPTIONS_GHC -fno-warn-orphans #-}


module Guide.Api.Types
  (
  -- * API
    Api
  , Site(..)
  , CategorySite(..)
  , ItemSite(..)
  , TraitSite(..)
  , SearchSite(..)

  -- * View types
  , CCategoryInfo(..), toCCategoryInfo
  , CCategoryFull(..), toCCategoryFull
  , CItemInfo(..), toCItemInfo
  , CItemFull(..), toCItemFull
  , CMarkdown(..), toCMarkdown
  , CTrait(..), toCTrait

  -- * Search
  , CSearchResult(..), toCSearchResult
  )
  where


import Imports

import qualified Data.Aeson as A
import Lucid (toHtml, renderText)
import Servant
import Servant.API.Generic
import Data.Swagger as S

import Guide.Api.Error
import Guide.Api.Utils
import Guide.Types.Core as G
import Guide.Search
import Guide.Utils (Uid(..), Url)
import Guide.Markdown (MarkdownBlock, MarkdownInline, MarkdownTree, mdHtml, mdSource)

----------------------------------------------------------------------------
-- Routes
----------------------------------------------------------------------------

-- | The description of the served API.
data Site route = Site
  { _categorySite :: route :-
      BranchTag "01. Categories" "Working with categories."
      :> ToServant CategorySite AsApi
  , _itemSite :: route :-
      BranchTag "02. Items" "Working with items."
      :> ToServant ItemSite AsApi
  , _traitSite :: route :-
      BranchTag "03. Item traits" "Working with item traits."
      :> ToServant TraitSite AsApi
  , _searchSite :: route :-
      BranchTag "04. Search" "Site-wide search."
      :> ToServant SearchSite AsApi
  }
  deriving (Generic)

-- | Working with categories
data CategorySite route = CategorySite
  { _getCategories :: route :-
      Summary "Get a list of available categories"
      :> Description "Primarily useful for displaying the main page. \
                     \The returned list is lightweight and doesn't contain \
                     \categories' contents."
      :> "categories"
      :> Get '[JSON] [CCategoryInfo]

  , _getCategory :: route :-
      Summary "Get contents of a category"
      :> ErrorResponse 404 "Category not found"
      :> "category"
      :> Capture "id" (Uid Category)
      :> Get '[JSON] CCategoryFull

  , _createCategory :: route :-
      Summary "Create a new category"
      :> Description "Returns the ID of the created category.\n\n\
                     \If a category with the same title already exists \
                     \in the group, returns its ID instead."
      :> ErrorResponse 400 "'title' not provided"
      :> "category"
      :> QueryParam' '[Required, Strict,
                       Description "Title of the newly created category"]
           "title" Text
      :> QueryParam' '[Required, Strict,
                       Description "Group to put the category into"]
           "group" Text
      :> Post '[JSON] (Uid Category)

  , _deleteCategory :: route :-
      Summary "Delete a category"
      :> "category"
      :> Capture "id" (Uid Category)
      :> Delete '[JSON] NoContent
  }
  deriving (Generic)

-- | Working with items
data ItemSite route = ItemSite
  { _createItem :: route :-
      Summary "Create a new item in the given category"
      :> Description "Returns the ID of the created item."
      :> ErrorResponse 400 "'name' not provided"
      :> "item"
      :> Capture "category" (Uid Category)
      :> QueryParam' '[Required, Strict] "name" Text
      :> Post '[JSON] (Uid Item)

  , _deleteItem :: route :-
      Summary "Delete an item"
      :> "item"
      :> Capture "id" (Uid Item)
      :> Delete '[JSON] NoContent
  }
  deriving (Generic)

-- | Working with item traits
data TraitSite route = TraitSite
  { _deleteTrait :: route :-
      Summary "Delete a trait"
      :> "item"
      :> Capture "item" (Uid Item)
      :> "trait"
      :> Capture "id" (Uid Trait)
      :> Delete '[JSON] NoContent
  }
  deriving (Generic)

-- | Site-wide search
data SearchSite route = SearchSite
  { _search :: route :-
      Summary "Search categories and items"
      :> Description "Note: returns at most 100 search results."
      :> ErrorResponse 400 "'query' not provided"
      :> "search"
      :> QueryParam' '[Required, Strict] "query" Text
      :> Get '[JSON] [CSearchResult]
  }
  deriving (Generic)

type Api = ToServant Site AsApi

----------------------------------------------------------------------------
-- Client types
--
-- These are more "light-weight" Haskell types of 'Guide'.
--
-- Furthermore using these "light-weight" types we keep all data small
-- to send these over the wire w/o having deep nested data,
-- we might not need on front-end.
----------------------------------------------------------------------------

-- | A "light-weight" client type of 'Category', which describes a category
-- but doesn't give the notes or the items.
data CCategoryInfo = CCategoryInfo
  { cciUid     :: Uid Category          ? "Category ID"
  , cciTitle   :: Text                  ? "Category title"
  , cciCreated :: UTCTime               ? "When the category was created"
  , cciGroup_  :: Text                  ? "Category group ('grandcategory')"
  , cciStatus  :: CategoryStatus        ? "Status (done, in progress, ...)"
  }
  deriving (Show, Generic)

instance A.ToJSON CCategoryInfo where
  toJSON = A.genericToJSON jsonOptions

instance ToSchema CCategoryInfo where
  declareNamedSchema = genericDeclareNamedSchema schemaOptions

-- | Factory to create a 'CCategoryInfo' from a 'Category'
toCCategoryInfo :: Category -> CCategoryInfo
toCCategoryInfo Category{..} = CCategoryInfo
  { cciUid     = H _categoryUid
  , cciTitle   = H _categoryTitle
  , cciCreated = H _categoryCreated
  , cciGroup_  = H _categoryGroup_
  , cciStatus  = H _categoryStatus
  }

-- | A "light-weight" client type of 'Category', which gives all available
-- information about a category
data CCategoryFull = CCategoryFull
  { ccfUid :: Uid Category              ? "Category ID"
  , ccfTitle :: Text                    ? "Category title"
  , ccfGroup :: Text                    ? "Category group ('grandcategory')"
  , ccfStatus :: CategoryStatus         ? "Status, e.g. done, in progress, ..."
  , ccfDescription :: CMarkdown         ? "Category description/notes (Markdown)"
  , ccfItems :: [CItemFull]             ? "All items in the category"
  }
  deriving (Show, Generic)

instance A.ToJSON CCategoryFull where
  toJSON = A.genericToJSON jsonOptions

instance ToSchema CCategoryFull where
  declareNamedSchema = genericDeclareNamedSchema schemaOptions

-- | Factory to create a 'CCategoryFull' from a 'Category'
toCCategoryFull :: Category -> CCategoryFull
toCCategoryFull Category{..} = CCategoryFull
  { ccfUid         = H $ _categoryUid
  , ccfTitle       = H $ _categoryTitle
  , ccfGroup       = H $ _categoryGroup_
  , ccfDescription = H $ toCMarkdown _categoryNotes
  , ccfItems       = H $ fmap toCItemFull _categoryItems
  , ccfStatus      = H $ _categoryStatus
  }

-- | A lightweight info type about an 'Item'
data CItemInfo = CItemInfo
  { ciiUid :: Uid Item                   ? "Item ID"
  , ciiName :: Text                      ? "Item name"
  , ciiCreated :: UTCTime                ? "When the item was created"
  , ciiGroup :: Maybe Text               ? "Item group"
  , ciiLink :: Maybe Url                 ? "Link to the official site, if exists"
  , ciiKind :: ItemKind                  ? "Item kind, e.g. library, ..."
  } deriving (Show, Generic)

instance A.ToJSON CItemInfo where
  toJSON = A.genericToJSON jsonOptions

instance ToSchema CItemInfo where
  declareNamedSchema = genericDeclareNamedSchema schemaOptions

-- | Client type of 'Item'
data CItemFull = CItemFull
  { cifUid :: Uid Item                   ? "Item ID"
  , cifName :: Text                      ? "Item name"
  , cifCreated :: UTCTime                ? "When the item was created"
  , cifGroup :: Maybe Text               ? "Item group"
  , cifDescription :: CMarkdown          ? "Item summary (Markdown)"
  , cifPros :: [CTrait]                  ? "Pros (positive traits)"
  , cifCons :: [CTrait]                  ? "Cons (negative traits)"
  , cifEcosystem :: CMarkdown            ? "The ecosystem description (Markdown)"
  , cifNotes :: CMarkdown                ? "Notes (Markdown)"
  , cifLink :: Maybe Url                 ? "Link to the official site, if exists"
  , cifKind :: ItemKind                  ? "Item kind, e.g. library, ..."
  } deriving (Show, Generic)

instance A.ToJSON CItemFull where
  toJSON = A.genericToJSON jsonOptions

instance ToSchema CItemFull where
  declareNamedSchema = genericDeclareNamedSchema schemaOptions

-- | Factory to create a 'CItemInfo' from an 'Item'
toCItemInfo :: Item -> CItemInfo
toCItemInfo Item{..} = CItemInfo
  { ciiUid         = H $ _itemUid
  , ciiName        = H $ _itemName
  , ciiCreated     = H $ _itemCreated
  , ciiGroup       = H $ _itemGroup_
  , ciiLink        = H $ _itemLink
  , ciiKind        = H $ _itemKind
  }

-- | Factory to create a 'CItemFull' from an 'Item'
toCItemFull :: Item -> CItemFull
toCItemFull Item{..} = CItemFull
  { cifUid         = H $ _itemUid
  , cifName        = H $ _itemName
  , cifCreated     = H $ _itemCreated
  , cifGroup       = H $ _itemGroup_
  , cifDescription = H $ toCMarkdown _itemDescription
  , cifPros        = H $ fmap toCTrait _itemPros
  , cifCons        = H $ fmap toCTrait _itemCons
  , cifEcosystem   = H $ toCMarkdown _itemEcosystem
  , cifNotes       = H $ toCMarkdown _itemNotes
  , cifLink        = H $ _itemLink
  , cifKind        = H $ _itemKind
  }

-- | Client type of 'Trait'
data CTrait = CTrait
  { ctUid :: Uid Trait                  ? "Trait ID"
  , ctContent :: CMarkdown              ? "Trait text (Markdown)"
  } deriving (Show, Generic)

instance A.ToJSON CTrait where
  toJSON = A.genericToJSON jsonOptions

instance ToSchema CTrait where
  declareNamedSchema = genericDeclareNamedSchema schemaOptions

-- | Factory to create a 'CTrait' from a 'Trait'
toCTrait :: Trait -> CTrait
toCTrait trait = CTrait
  { ctUid     = H $ trait ^. uid
  , ctContent = H $ toCMarkdown $ trait ^. content
  }

-- | Client type of 'Markdown'
data CMarkdown = CMarkdown
  { text :: Text                        ? "Markdown source"
  , html :: Text                        ? "Rendered HTML"
  } deriving (Show, Generic)

instance A.ToJSON CMarkdown
instance ToSchema CMarkdown

-- | Type class to create 'CMarkdown'
class ToCMarkdown md where toCMarkdown :: md -> CMarkdown

instance ToCMarkdown MarkdownInline where
  toCMarkdown md = CMarkdown
    { text = H $ md^.mdSource
    , html = H $ toText $ md^.mdHtml
    }

instance ToCMarkdown MarkdownBlock where
  toCMarkdown md = CMarkdown
    { text = H $ md^.mdSource
    , html = H $ toText $ md^.mdHtml
    }

instance ToCMarkdown MarkdownTree where
  toCMarkdown md = CMarkdown
    { text = H $ md^.mdSource
    , html = H $ toText . renderText $ toHtml md
    }

----------------------------------------------------------------------------
-- Search client types
----------------------------------------------------------------------------

-- | Client type of 'SearchResult'
data CSearchResult
  -- | Match was found in category title
  = CSRCategoryResult CSRCategory
  -- | Match was found in the item
  | CSRItemResult CSRItem
  deriving (Show, Generic)

instance A.ToJSON CSearchResult where
  toJSON = \case
    CSRCategoryResult cat -> A.object
      [ "tag" A..= ("Category" :: Text)
      , "contents" A..= cat
      ]
    CSRItemResult item -> A.object
      [ "tag" A..= ("Item" :: Text)
      , "contents" A..= item
      ]

instance ToSchema CSearchResult where
  declareNamedSchema = genericDeclareNamedSchema schemaOptions
    { constructorTagModifier = \case
        "CSRCategoryResult" -> "Category"
        "CSRItemResult" -> "Item"
        other -> error ("CSearchResult schema: unknown tag " <> show other)
    }
    & mapped.mapped.schema.S.description ?~
        "The docs lie. The true schema for this type is an object with two \
        \parameters 'tag' and 'contents', where 'tag' is one of keys listed \
        \in this doc, and 'contents' is the object."

-- | A category was found.
data CSRCategory = CSRCategory
  { csrcInfo         :: CCategoryInfo  ? "Info about the category"
  , csrcDescription  :: CMarkdown      ? "Category description"
  } deriving (Show, Generic)

instance A.ToJSON CSRCategory where
  toJSON = A.genericToJSON jsonOptions

instance ToSchema CSRCategory where
  declareNamedSchema = genericDeclareNamedSchema schemaOptions

-- | An item was found.
data CSRItem = CSRItem
  { csriCategory    :: CCategoryInfo    ? "Category that the item belongs to"
  , csriInfo        :: CItemInfo        ? "Info about the item"
  , csriDescription :: Maybe CMarkdown  ? "Item description (if the match was found there)"
  , csriEcosystem   :: Maybe CMarkdown  ? "Item ecosystem (if the match was found there)"
  } deriving (Show, Generic)

instance A.ToJSON CSRItem where
  toJSON = A.genericToJSON jsonOptions

instance ToSchema CSRItem where
  declareNamedSchema = genericDeclareNamedSchema schemaOptions

toCSearchResult :: SearchResult -> CSearchResult
toCSearchResult (SRCategory cat) =
  CSRCategoryResult $ CSRCategory
    { csrcInfo        = H $ toCCategoryInfo cat
    , csrcDescription = H $ toCMarkdown (cat ^. G.notes)
    }
toCSearchResult (SRItem cat item) =
  CSRItemResult $ CSRItem
    { csriCategory    = H $ toCCategoryInfo cat
    , csriInfo        = H $ toCItemInfo item
    , csriDescription = H $ Just (toCMarkdown (item ^. G.description))
    , csriEcosystem   = H $ Nothing
    }
-- TODO: currently if there are matches in both description and category,
-- we'll show two matches instead of one
toCSearchResult (SRItemEcosystem cat item) =
  CSRItemResult $ CSRItem
    { csriCategory    = H $ toCCategoryInfo cat
    , csriInfo        = H $ toCItemInfo item
    , csriDescription = H $ Nothing
    , csriEcosystem   = H $ Just (toCMarkdown (item ^. ecosystem))
    }

----------------------------------------------------------------------------
-- Schema instances
----------------------------------------------------------------------------

instance ToParamSchema (Uid Category) where
  toParamSchema _ = mempty
    & S.type_ .~ SwaggerString
    & S.format ?~ "Category ID"

instance ToParamSchema (Uid Item) where
  toParamSchema _ = mempty
    & S.type_ .~ SwaggerString
    & S.format ?~ "Item ID"

instance ToParamSchema (Uid Trait) where
  toParamSchema _ = mempty
    & S.type_ .~ SwaggerString
    & S.format ?~ "Trait ID"

instance ToSchema (Uid Category) where
  declareNamedSchema _ = pure $ NamedSchema (Just "CategoryID") $ mempty
    & S.type_ .~ SwaggerString

instance ToSchema (Uid Item) where
  declareNamedSchema _ = pure $ NamedSchema (Just "ItemID") $ mempty
    & S.type_ .~ SwaggerString

instance ToSchema (Uid Trait) where
  declareNamedSchema _ = pure $ NamedSchema (Just "TraitID") $ mempty
    & S.type_ .~ SwaggerString

instance ToSchema CategoryStatus

instance ToSchema ItemKind where
  declareNamedSchema _ = pure $ NamedSchema (Just "ItemKind") $ mempty
    & S.type_ .~ SwaggerObject
    & S.format ?~ "Can be one of the three things:\
                  \ {tag: Library, contents: <package name>}\
                  \ * {tag: Tool, contents: <package name>}\
                  \ * {tag: Other}"
