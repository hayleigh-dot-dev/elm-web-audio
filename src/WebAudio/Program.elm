module WebAudio.Program exposing
  ( element
  , document
  , application
  )

{-| Each of the functions contained in this module are wrappers for the existing
Browser application types. They need just to additions to the record:

- An audio function that takes your model and returns a `WebAudio.Graph`.

```elm
audio : Model -> WebAudio.Graph
audio model =
  List.map voice model.notes
```

- A port to send the encoded audio graph to javascript.

```elm
port audioPort : Json.Encode.Value -> Cmd msg
```

With these programs, your audio function is called automatically after every
update just like your view function is. So if we wanted to create a
Browser.element program, we'd instead do:

```elm
main : Program () Model Msg
main =
  WebAudio.Program.element
    { init = init
    , update = update
    , audio = audio
    , view = view
    , subscriptions = subscriptions
    , audioPort = audioPort
    }
```

The only program from Browser not support is `Browser.sandbox` as those
programs cannot produce Cmds and so can't call the port needed to send our audio
graph to javascript.

@docs element, document, application

-}

-- Imports ---------------------------------------------------------------------
import Browser
import Browser.Navigation exposing (Key)
import Html exposing (Html)
import Json.Encode exposing (Value)
import Url exposing (Url)
import WebAudio

-- Utils -----------------------------------------------------------------------
withAudio : (Value -> Cmd msg) -> (model -> WebAudio.Graph) -> ( model, Cmd msg ) -> ( model, Cmd msg )
withAudio audioPort audioFunc ( model, cmd ) =
  ( model
  , Cmd.batch 
    [ cmd
    , audioFunc model |> WebAudio.encodeGraph |> audioPort
    ]
  )

-- Programs --------------------------------------------------------------------
{-|
-}
element :
  { init : flags -> ( model, Cmd msg )
  , update : msg -> model -> ( model, Cmd msg )
  , audio : model -> WebAudio.Graph
  , view : model -> Html msg
  , subscriptions : model -> Sub msg
  , audioPort : Value -> Cmd msg
  }
  -> Program flags model msg
element { init, update, audio, view, subscriptions, audioPort } =
  Browser.element
    { init = \flags -> init flags |> withAudio audioPort audio
    , update = \msg model -> update msg model |> withAudio audioPort audio
    , view = view
    , subscriptions = subscriptions
    }

{-|
-}
document :
  { init : flags -> ( model, Cmd msg )
  , update : msg -> model -> ( model, Cmd msg )
  , audio : model -> WebAudio.Graph
  , view : model -> Browser.Document msg
  , subscriptions : model -> Sub msg
  , audioPort : Value -> Cmd msg
  }
  -> Program flags model msg
document { init, update, audio, view, subscriptions, audioPort } =
  Browser.document
    { init = \flags -> init flags |> withAudio audioPort audio
    , update = \msg model -> update msg model |> withAudio audioPort audio
    , view = view
    , subscriptions = subscriptions
    }

{-|
-}
application :
  { init : flags -> Url -> Key -> (model, Cmd msg)
  , update : msg -> model -> ( model, Cmd msg )
  , audio : model -> WebAudio.Graph
  , view : model -> Browser.Document msg
  , subscriptions : model -> Sub msg
  , audioPort : Value -> Cmd msg
  , onUrlRequest : Browser.UrlRequest -> msg
  , onUrlChange : Url -> msg
  }
  -> Program flags model msg
application { init, update, audio, view, subscriptions, audioPort, onUrlRequest, onUrlChange } =
  Browser.application
    { init = \flags url key -> init flags url key |> withAudio audioPort audio
    , update = \msg model -> update msg model |> withAudio audioPort audio
    , view = view
    , subscriptions = subscriptions
    , onUrlRequest = onUrlRequest
    , onUrlChange = onUrlChange
    }