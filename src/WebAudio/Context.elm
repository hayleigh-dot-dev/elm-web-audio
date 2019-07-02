module WebAudio.Context exposing
  (AudioContext, State(..)
  , currentTime, sampleRate, state, baseLatency, outputLatency
  , every
  )

{-|

@docs AudioContext, State

@docs currentTime, sampleRate, state, baseLatency, outputLatency

@docs every

-}

import Json.Decode as Decode exposing (Decoder)
import Time

-- Types -----------------------------------------------------------------------
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
type alias AudioContext = Decode.Value

{-| The state of an AudioContext encoded as a nice Elm union type. Mostly handy
to prevent unecessary calcultions of audio graphs if the context is suspended or
closed.
-}
type State
  = Suspended
  | Running
  | Closed

-- Accessors -------------------------------------------------------------------
currentTimeDecoder : Decoder Float
currentTimeDecoder =
  Decode.field "currentTime" Decode.float

{-| Get the time since an AudioContext was started. This is necessary if you want
to use scheduled audio properties to update values in the future (like an amplitude
envelope perhaps).
-}
currentTime : AudioContext -> Float
currentTime context =
  case Decode.decodeValue currentTimeDecoder context of
    Ok time -> time
    Err _   -> 0

sampleRateDecoder : Decoder Float
sampleRateDecoder =
  Decode.field "sampleRate" Decode.float

{-| Find out what sample rate an AudioContext is running at, in samples per second.
-}
sampleRate : AudioContext -> Float
sampleRate context =
  case Decode.decodeValue sampleRateDecoder context of
    Ok sr -> sr
    Err _ -> 0

stateDecoder : Decoder State
stateDecoder =
  Decode.field "state" Decode.string
    |> Decode.andThen (\state_ ->
      case state_ of
        "suspended" ->
          Decode.succeed Suspended
        "running" ->
          Decode.succeed Running
        "closed" ->
          Decode.succeed Closed
        _ ->
          Decode.fail "Unkown AudioContext state."
    )

{-| Find out what state an AudioContext is currently in. An AudioContext can either
be Suspended, Running, or Closed. 

It is common for AudioContexts to start in a Suspended state and must be resumed
after some user interaction event. By using a port we can resume an AudioContext
after a user interactios with our Elm app.
-}
state : AudioContext -> State
state context =
  case Decode.decodeValue stateDecoder context of
    Ok state_  -> state_
    Err _     -> Closed

baseLatencyDecoder : Decoder Float
baseLatencyDecoder =
  Decode.field "baseLatency" Decode.float

{-| The base latency of an AudioContext is the number of seconds of processing
latency incurred by the AudioContext passing the audio from the AudioDestinationNode
to the audio subsystem.
-}
baseLatency : AudioContext -> Float
baseLatency context =
  case Decode.decodeValue baseLatencyDecoder context of
    Ok l  -> l
    Err _ -> 0

outputLatencyDecoder : Decoder Float
outputLatencyDecoder =
  Decode.field "outputLatency" Decode.float

{-| The output latency of an Audio Context is the time, in seconds, between the 
browser requesting the host system to play a buffer and the time at which the first 
sample in the buffer is actually processed by the audio output device.
-}
outputLatency : AudioContext -> Float
outputLatency context =
  case Decode.decodeValue outputLatencyDecoder context of
    Ok l  -> l
    Err _ -> 0

-- Subscriptions ---------------------------------------------------------------
{-|
-}
every : Float -> Float -> (Float -> msg) -> AudioContext -> Sub msg
every interval prev msg context =
  Time.every 25 (\_ ->
    let
      lookahead = 0.1
      target = prev + interval
      curr = currentTime context
      diff = target - curr
    in
      if curr >= target - lookahead then
        msg (curr + diff)
      else
        msg prev
  )
