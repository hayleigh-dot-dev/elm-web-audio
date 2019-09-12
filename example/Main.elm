port module Main exposing (..)

import Browser
import Browser.Events
--
import Html exposing (Html, Attribute, a, div, pre, p, code, h1, text, main_, button)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
--
import Json.Decode
import Json.Encode
--
import WebAudio
import WebAudio.Property as Prop
import WebAudio.Program

-- Send the JSON encoded audio graph to javascript
port updateAudio : Json.Encode.Value -> Cmd msg

-- MAIN -----------------------------------------------------------------------
main : Program () Model Msg
main =
  WebAudio.Program.element
    { init = init
    , update = update
    , audio = audio
    , view = view
    , subscriptions = subscriptions
    , audioPort = updateAudio
    }

-- MODEL ----------------------------------------------------------------------
--
type alias Note =
  { key : String
  , midi : Float
  , triggered : Bool
  }

--
type alias Model =
  { notes : List Note
  }

--
initialModel : Model
initialModel =
  { notes =
    [ { key = "a", midi = 60, triggered = False }
    , { key = "s", midi = 62, triggered = False }
    , { key = "d", midi = 64, triggered = False }
    , { key = "f", midi = 65, triggered = False }
    , { key = "g", midi = 67, triggered = False }
    , { key = "h", midi = 69, triggered = False }
    , { key = "j", midi = 71, triggered = False }
    , { key = "k", midi = 72, triggered = False }
    , { key = "l", midi = 74, triggered = False }
    ]
  }

--
init : () -> (Model, Cmd Msg)
init _ =
  ( initialModel
  , Cmd.none
  )

-- UPDATE ---------------------------------------------------------------------
type Msg
  = NoOp
  --
  | NoteOn String
  | NoteOff String
  --
  | TransposeUp
  | TransposeDown

--
noteOn : String -> Model -> Model
noteOn key model = 
  { model 
  | notes = List.map (\note -> if note.key == key then { note | triggered = True } else note) model.notes 
  }

--
noteOff : String -> Model -> Model
noteOff key model = 
  { model 
  | notes = List.map (\note -> if note.key == key then { note | triggered = False } else note) model.notes 
  }

transposeUp : Model -> Model
transposeUp model =
  { model
  | notes = List.map (\note -> { note | midi = note.midi + 1 }) model.notes
  }

transposeDown : Model -> Model
transposeDown model =
  { model
  | notes = List.map (\note -> { note | midi = note.midi - 1 }) model.notes
  }

--
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp -> 
      Tuple.pair model Cmd.none

    NoteOn key ->
      ( noteOn key model
      , Cmd.none
      )

    NoteOff key ->
      ( noteOff key model
      , Cmd.none
      )

    TransposeUp ->
      ( transposeUp model
      , Cmd.none
      )

    TransposeDown ->
      ( transposeDown model
      , Cmd.none
      )

-- AUDIO ----------------------------------------------------------------------
-- Super simple utility function that takes a MIDI note number like 60 and
-- converts it to the corresponding frequency in Hertz. We use Float for the
-- MIDI number to allow for detuning, and we assume A4 is MIDI note number
-- 69.
mtof : Float -> Float
mtof midi =
  440 * 2 ^ ((midi - 69) / 12)

-- This takes a Note (as defined above) and converts that to a synth voice.
voice : Note -> WebAudio.Node
voice note =
  WebAudio.oscillator [ Prop.frequency <| mtof note.midi ]
    [ WebAudio.gain [ Prop.gain <| if note.triggered then 0.1 else 0 ]
      [ WebAudio.dac ]
    ]

-- On the js side, the virtual audio graph is expecting an array of virtual
-- nodes. This plays nicely with our list of Notes, we can simply map the
-- Notes to synth voices and encode the new list.
-- Returns a Cmd Msg as we call the port from within this function (rather
-- than returning the encoded JSON).
audio : Model -> WebAudio.Graph
audio model =
  List.map voice model.notes

-- VIEW -----------------------------------------------------------------------
-- Use this to toggle the main styling on a note based on wheter it is currently
-- active or note. Basically just changes the background and font colour.
noteCSS : Bool -> String
noteCSS active =
  if active then
    "bg-indigo-500 text-white font-bold py-2 px-4 rounded"
  else
    "bg-indigo-100 text-black font-bold py-2 px-4 rounded"

-- This takes a Note (as defined above) and converts that to some  Notice
-- how we use the data for both the `voice` function and this `noteView` function.
-- Our audio graph should never become out of sync with our view!
noteView : Note -> Html Msg
noteView note =
  div [ class <| noteCSS note.triggered, class "flex-1 mx-2 text-center" ]
    [ text note.key ]

audioView : List Note -> List (Html Msg)
audioView =
  List.map (\note ->
    voice note |> WebAudio.encode |> Json.Encode.encode 2 |> (\json ->
      pre [ class "text-xs", class <| if note.triggered then "text-gray-800" else "text-gray-500" ] 
        [ code [ class "my-2" ] 
          [ text json ] 
        ]
    )
  )

--
view : Model -> Html Msg
view model =
  main_ [ class "m-10" ]
    [ h1 [ class "text-3xl my-10" ]
        [ text "elm-web-audio" ]
    , p [ class "p-2 my-6" ]
        [ text """This package provides an elm/html-like API for declaring Web 
          Audio graphs in Elm. The intention being that these `virtual` audio 
          graphs are then sent via a port to be constructed by a javascript. 
          There is a reference implementation of this found in the repository 
          that you are free to copy until I or someone else releases a package 
          formally.""" ]
    , p [ class "p-2 my-6" ]
        [ text """This site primarily serves as a demonstration that the library
          actually works. If you'd like some more in depth documentation on the
          Elm library itself you should check out the package """
        , a [ href "https://package.elm-lang.org/packages/pd-andy/elm-web-audio/1.0.0/"
            , class "text-indigo-500 hover:text-indigo-700"
            ] 
            [ text "here." ]  
        ]
    , p [ class "p-2 my-6" ]
        [ text """A Web Audio context typically starts in a suspended state. 
          If you can't hear any sound, click anywhere to resume the audio 
          context.""" ]
    , div [ class "p-2 my-6" ]
        [ button [ onClick TransposeUp, class "bg-indigo-500 text-white font-bold py-2 px-4 mr-4 rounded" ]
            [ text "Transpose up" ]
        , button [ onClick TransposeDown, class "bg-indigo-500 text-white font-bold py-2 px-4 rounded" ]
            [ text "Transpose down" ]
        ]
    , div [ class "flex" ]
        <| List.map noteView model.notes
    , div [ class "p-2 my-10" ]
        [ text """Below is the json send via ports to javascript. Active notes 
          are highlighted.""" ]
    , div [ class "bg-gray-200 p-2 my-10 rounded h-64 overflow-scroll"]
        <| audioView model.notes
    ]

-- SUBSCRIPTIONS --------------------------------------------------------------
--
noteOnDecoder : List Note -> Json.Decode.Decoder Msg
noteOnDecoder notes =
  Json.Decode.field "key" Json.Decode.string
    |> Json.Decode.andThen (\key ->
      case List.any (\note -> note.key == key) notes of
        True ->
          Json.Decode.succeed (NoteOn key)
        False ->
          Json.Decode.fail ""
    )

--
noteOffDecoder : List Note -> Json.Decode.Decoder Msg
noteOffDecoder notes =
  Json.Decode.field "key" Json.Decode.string
    |> Json.Decode.andThen (\key ->
      case List.any (\note -> note.key == key) notes of
        True ->
          Json.Decode.succeed (NoteOff key)
        False ->
          Json.Decode.fail ""
    )

--
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Browser.Events.onKeyDown <| noteOnDecoder model.notes
    , Browser.Events.onKeyUp <| noteOffDecoder model.notes
    ]