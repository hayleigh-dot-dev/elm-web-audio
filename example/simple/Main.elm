port module Main exposing (Model, Msg(..), audio, fromElm, init, initialModel, main, subscriptions, update, updateAudio, view)

import Browser
import Html exposing (..)
import Html.Attributes as Attr exposing (class)
import Html.Events as Event exposing (onClick)
import Json.Encode as Encode
import WebAudio
import WebAudio.Keyed as Keyed
import WebAudio.Property as Prop

-- Send the JSON encoded audio graph to javascript
port fromElm : Encode.Value -> Cmd msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { freq : Float
    , gain : Float
    }


initialModel =
    { freq = 440
    , gain = 0.1
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, updateAudio initialModel )


type Msg
    = NoOp
    | DoubleFreq
    | HalfFreq
    | IncrGain
    | DecrGain


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, updateAudio model )

        DoubleFreq ->
            { model | freq = model.freq * 2 } |> (\m -> ( m, updateAudio m ))

        HalfFreq ->
            { model | freq = model.freq / 2 } |> (\m -> ( m, updateAudio m ))

        IncrGain ->
            { model | gain = model.gain + 0.1 } |> (\m -> ( m, updateAudio m ))

        DecrGain ->
            { model | gain = model.gain - 0.1 } |> (\m -> ( m, updateAudio m ))



-- Whenever you would use Cmd.none in update, instead call
-- this to trigger the audio graph to update and be sent to
-- javascript.
updateAudio : Model -> Cmd msg
updateAudio =
    audio >> Encode.list WebAudio.encode >> fromElm


audio : Model -> WebAudio.Graph
audio model =
    [ WebAudio.osc [ Prop.freq model.freq ]
        [ WebAudio.gain [ Prop.gain model.gain ]
            [ WebAudio.dac ]
        ]
    ]


view : Model -> Html Msg
view model =
    div [ class "section" ]
        [ div [ class "container has-text-centered" ]
            [ h1 [ class "title" ] [ text "elm-web-audio" ]
            , br [] []
            ]
        , div [ class "level is-mobile" ]
            [ button [ onClick HalfFreq, class "button level-item" ] [ text "-" ]
            , p [ class "level-item" ] [ text <| String.fromFloat model.freq ++ "Hz" ]
            , button [ onClick DoubleFreq, class "button level-item" ] [ text "+" ]
            ]
        , div [ class "level is-mobile" ]
            [ button [ onClick DecrGain, class "button level-item" ] [ text "-" ]
            , p [ class "level-item" ] [ text <| String.left 3 <| String.fromFloat model.gain ]
            , button [ onClick IncrGain, class "button level-item" ] [ text "+" ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
