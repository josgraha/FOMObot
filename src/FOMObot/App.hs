module FOMObot.App
    ( runApp
    ) where

import System.Environment (getEnv)
import Data.Maybe (fromJust)
import Network.URI (parseURI)
import Control.Lens ((^.))
import Control.Monad.Trans (liftIO)
import Control.Monad.Reader (ask)
import Control.Monad.State (get, put)
import Network.Wreq (responseBody)
import Data.Aeson (eitherDecode, encode)
import qualified Data.Text as T
import qualified Network.WebSockets as WS

import FOMObot.RTM (rtmStartResponse)
import FOMObot.Websockets (runSecureClient)
import FOMObot.Types.RTMStartResponse
import FOMObot.Types.Message
import FOMObot.Types.Bot

processMessage :: Either String Message -> Bot ()
processMessage = either doNothing printMessage
    where
        doNothing = const $ return ()

printMessage :: Message -> Bot ()
printMessage m@(Message t _ _ _)
    | t == "message" = liftIO $ print m
    | otherwise = return ()

alertChannel :: String -> Bot ()
alertChannel channel = do
    connection <- ask
    liftIO $ print message
    liftIO $ WS.sendTextData connection responseData
    where
        responseData = encode message
        message = Message "message" channel "" $ concat ["Check out <#", channel, ">"]

runBot :: Bot ()
runBot = do
    connection <- ask
    state <- get

    message <- liftIO $ WS.receiveData connection
    processMessage $ eitherDecode message
    liftIO $ print $ "state: " ++ (show state)
    modify (+1)

runApp :: IO ()
runApp = do
    token <- T.pack <$> getEnv "SLACK_API_TOKEN"
    response <- rtmStartResponse token
    let socketURL = _url $ response ^. responseBody
    let uri = fromJust $ parseURI socketURL
    runSecureClient uri runBot
