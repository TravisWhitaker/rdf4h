module W3C.W3CAssertions where

import qualified Data.Text as T
import           Data.RDF
import qualified Test.HUnit as TU
import           Test.Tasty
import           W3C.Manifest

runManifestTests :: (TestEntry -> TestTree) -> Manifest -> TestTree
runManifestTests mfEntryToTest manifest =
    testGroup (T.unpack $ description manifest) $ map mfEntryToTest $ entries manifest

assertIsIsomorphic :: forall rdf1 rdf2.
                      (Show rdf1, Show rdf2, RDF rdf1, RDF rdf2) =>
                      IO rdf1 -> IO rdf2 -> IO ()
assertIsIsomorphic r1 r2 = do
  gr1 <- r1
  gr2 <- r2
  TU.assertBool ("not isomorphic: " ++ show gr1 ++ " compared with " ++ show gr2) (isSame gr1 gr2) -- (isGraphIsomorphic gr1 gr2)

      where
        noBlankNodes g = (all noBlanks . expandTriples) g
        noBlanks (Triple s p o) = not (blankNode s)
                               && not (blankNode p)
                               && not (blankNode o)
        blankNode (BNode _)    = True
        blankNode (BNodeGen _) = True
        blankNode _            = False
        isSame g1 g2 =
            if (noBlankNodes g1) && (noBlankNodes g2)
            -- can compare URIs and literals as well as structure
            then isIsomorphic g1 g2
            -- cannot compare blank nodes with generated blank nodes,
            -- so instead just compare the RDF graph structure of the
            -- mf:action parsed RDF with the expected mf:result structure.
            else isGraphIsomorphic g1 g2

assertIsParsed :: (Show rdf, RDF rdf) => IO (Either ParseFailure rdf) -> TU.Assertion
assertIsParsed r1 = do
  gr1 <- r1
  TU.assertBool ("unable to parse, reason:\n" ++ show gr1) (isParsed gr1)

assertIsNotParsed :: (Show rdf, RDF rdf) => IO (Either ParseFailure rdf) -> TU.Assertion
assertIsNotParsed r1 = do
  gr1 <- r1
  TU.assertBool ("parsed unexpectantly:\n" ++ show gr1) (not (isParsed gr1))

isParsed :: Either a b -> Bool
isParsed (Left _) = False
isParsed (Right _) = True

nodeURI :: Node -> String
nodeURI (UNode u) = T.unpack u
nodeURI node = error $ "W3CAssertions: unexpected node in `nodeURI`: " ++ show node
