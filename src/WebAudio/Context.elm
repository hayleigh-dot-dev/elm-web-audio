module WebAudio.Context exposing
    ( AudioContext, State(..)
    , from
    , currentTime, sampleRate, state, baseLatency, outputLatency
    , every, at
    )

{-|


# Types

@docs AudioContext, State


# Constructors

@docs from


# AudioContext Property Accessors

@docs currentTime, sampleRate, state, baseLatency, outputLatency


# Subscriptions

@docs every, at

-}

import Json.Decode
import Time



-- TYPES -----------------------------------------------------------------------


{-| An AudioContext is a simple alias for a Json.Decode.Value. By making clever
use of a context's [computed properties](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/get)
we can decode information such as the current time or the context's state whenver
we need it.

```javascript
const context = new AudioContext()
const App = Elm.Main.init({
  node: document.querySelector('#app'),
  flags: context
})
```

By passing an AudioContext to the Elm app through flags, we can pass it on to the
property accessors below whenever we need to query the state of the context.

-}
type AudioContext
    = AudioContext Json.Decode.Value


{-| The state of an AudioContext encoded as a nice Elm union type. Mostly handy
to prevent unecessary calcultions of audio graphs if the context is suspended or
closed.
-}
type State
    = Suspended
    | Running
    | Closed



-- CONSTRUCTORS ----------------------------------------------------------------


{-| -}
from : Json.Decode.Value -> Maybe AudioContext
from js =
    let
        -- Decode the three properties that exist on the `BaseAudioContext`
        -- interface that we actually use. If any of them fail, we know that the
        -- value is not an AudioContext!
        --
        -- We don't actually care about the values, though, so we use the
        -- `Json.Decode.value` decoder to essentially just check the eistence of
        --a property and then "wrap" it back up in an opaque `Value`.
        --
        -- https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext
        --
        -- This will work on any classes that extend BaseAudioContext, so any
        -- custom AudioContexts should work too, it'll also work on anything
        -- that has a `currentTime`, `sampleRate`, and `state` property.
        decoder =
            Json.Decode.map3 (\_ _ _ -> ())
                -- (Json.Decode.field "audioWorklet" Json.Decode.value)
                (Json.Decode.field "currentTime" Json.Decode.value)
                -- (Json.Decode.field "destination" Json.Decode.value)
                -- (Json.Decode.field "listener" Json.Decode.value)
                (Json.Decode.field "sampleRate" Json.Decode.value)
                (Json.Decode.field "state" Json.Decode.value)
                |> Json.Decode.map (\_ -> AudioContext js)
    in
    Json.Decode.decodeValue decoder js
        |> Result.toMaybe



-- QUERIES ---------------------------------------------------------------------


{-| Get the time since an AudioContext was started. This is necessary if you want
to use scheduled audio properties to update values in the future (like an amplitude
envelope perhaps).
-}
currentTime : AudioContext -> Float
currentTime (AudioContext context) =
    let
        currentTimeDecoder =
            Json.Decode.field "currentTime" Json.Decode.float
    in
    case Json.Decode.decodeValue currentTimeDecoder context of
        Ok time ->
            time

        -- ❗️ DANGER ZONE
        --
        -- This infintie loop will explode the stack if the context is not an
        -- `AudioContext`! This can only happen if there's a bug with this
        -- package, because we restrict construction of the opaque `AudioContext`
        -- typing using the `from` function above.
        Err _ ->
            currentTime <| AudioContext context


{-| Find out what sample rate an AudioContext is running at, in samples per second.
-}
sampleRate : AudioContext -> Float
sampleRate (AudioContext context) =
    let
        sampleRateDecoder =
            Json.Decode.field "sampleRate" Json.Decode.float
    in
    case Json.Decode.decodeValue sampleRateDecoder context of
        Ok rate ->
            rate

        -- ❗️ DANGER ZONE
        --
        -- This infintie loop will explode the stack if the context is not an
        -- `AudioContext`! This can only happen if there's a bug with this
        -- package, because we restrict construction of the opaque `AudioContext`
        -- typing using the `from` function above.
        Err _ ->
            sampleRate <| AudioContext context


{-| Find out what state an AudioContext is currently in. An AudioContext can either
be Suspended, Running, or Closed.

It is common for AudioContexts to start in a Suspended state and must be resumed
after some user interaction event. By using a port we can resume an AudioContext
after a user interactios with our Elm app.

-}
state : AudioContext -> State
state (AudioContext context) =
    let
        stateDecoder =
            Json.Decode.field "state" Json.Decode.string
                |> Json.Decode.andThen
                    (\state_ ->
                        case state_ of
                            "suspended" ->
                                Json.Decode.succeed Suspended

                            "running" ->
                                Json.Decode.succeed Running

                            "closed" ->
                                Json.Decode.succeed Closed

                            _ ->
                                Json.Decode.fail ""
                    )
    in
    case Json.Decode.decodeValue stateDecoder context of
        Ok stat ->
            stat

        -- ❗️ DANGER ZONE
        --
        -- This infintie loop will explode the stack if the context is not an
        -- `AudioContext`! This can only happen if there's a bug with this
        -- package, because we restrict construction of the opaque `AudioContext`
        -- typing using the `from` function above.
        Err _ ->
            state <| AudioContext context


{-| The base latency of an AudioContext is the number of seconds of processing
latency incurred by the AudioContext passing the audio from the AudioDestinationNode
to the audio subsystem.
-}
baseLatency : AudioContext -> Float
baseLatency (AudioContext context) =
    let
        baseLatencyDecoder =
            Json.Decode.field "baseLatency" Json.Decode.float
    in
    case Json.Decode.decodeValue baseLatencyDecoder context of
        Ok latency ->
            latency

        -- ❗️ DANGER ZONE
        --
        -- This infintie loop will explode the stack if the context is not an
        -- `AudioContext`! This can only happen if there's a bug with this
        -- package, because we restrict construction of the opaque `AudioContext`
        -- typing using the `from` function above.
        Err _ ->
            baseLatency <| AudioContext context


{-| The output latency of an Audio Context is the time, in seconds, between the
browser requesting the host system to play a buffer and the time at which the first
sample in the buffer is actually processed by the audio output device.
-}
outputLatency : AudioContext -> Float
outputLatency (AudioContext context) =
    let
        outputLatencyDecoder =
            Json.Decode.field "outputLatency" Json.Decode.float
    in
    case Json.Decode.decodeValue outputLatencyDecoder context of
        Ok latency ->
            latency

        -- ❗️ DANGER ZONE
        --
        -- This infintie loop will explode the stack if the context is not an
        -- `AudioContext`! This can only happen if there's a bug with this
        -- package, because we restrict construction of the opaque `AudioContext`
        -- typing using the `from` function above.
        Err _ ->
            outputLatency <| AudioContext context



-- SUBSCRIPTIONS ---------------------------------------------------------------


{-| This function works like Time.every, and allows us to get an AudioContext's
current time according to some interval. There are some important differences
between this and Time.every, however.

In javascript land setInterval can be hugely inconsistent, making musical timing
difficult as the interval drifts over time. To combat this we can combine setInterval
with a short interval and an AudioContext to look ahead in time, making it possible
to schedule sample-accurate updates.

Because of this, the AudioContext time returned by `every` will usually be a few
milliseconds in the future. This works great when combined with scheduled parameter
updates!

    type alias Model =
        { time : Float
      , context : AudioContext
      , freq : Float
      , ...
      }

    type Msg
      = NoOp
      | NextStep Float
      | ...

    audio model =
      osc [ setValueAtTime (freq model.freq) model.time ]
        [ dac ]

    ...

    -- Every 250ms move to the next step in a sequencer.
    subscriptions model =
      every 0.25 model.time NoOp NextStep model.context

Because we poll rapidly with Time.every, we provide a NoOp msg to return whenver
we're _not_ at the next time interval. This is a necessary evil because of how
Elm handles time subscriptions.

-}
every : Float -> Float -> msg -> (Float -> msg) -> AudioContext -> Sub msg
every interval prev noop msg context =
    Time.every 25
        (\_ ->
            let
                lookahead =
                    0.1

                target =
                    prev + interval

                curr =
                    currentTime context

                diff =
                    target - curr
            in
            if curr >= target - lookahead then
                msg (curr + diff)

            else
                noop
        )


{-| -}
at : Float -> msg -> (Float -> msg) -> AudioContext -> Sub msg
at target noop msg context =
    if currentTime context >= target then
        Sub.none

    else
        Time.every 25
            (\_ ->
                let
                    lookahead =
                        0.1

                    curr =
                        currentTime context

                    diff =
                        target - curr
                in
                if curr >= target - lookahead then
                    msg (curr + diff)

                else
                    noop
            )
