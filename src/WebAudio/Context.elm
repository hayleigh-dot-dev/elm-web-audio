module WebAudio.Context exposing
  ( AudioContext, State(..)
  , currentTime, sampleRate, state, baseLatency, outputLatency
  , every, every_
  )

{-|

# Types
@docs AudioContext, State

# AudioContext Property Accessors
@docs currentTime, sampleRate, state, baseLatency, outputLatency

# Subscriptions
@docs every, every_

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

{-| The state of an AudioContext as a string. Occassionally useful if you need
to display this information to the user.
-}
stateToString : State -> String
stateToString state_ =
  case state_ of
    Suspended -> "Suspended"
    Running -> "Running"
    Closed -> "Closed"

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
we're *not* at the next time interval. This is a necessary evil because of how
Elm handles time subscriptions. 
-}
every : Float -> Float -> msg -> (Float -> msg) -> AudioContext -> Sub msg
every interval prev noop msg context =
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
        noop
  )

{-| An alternative version of Context.every that allows you to supply the polling
time for Time.every. The standard function polls the AudioContext current time
every 25ms. This is fine for most applications, but can flood the update function
with many NoOp msgs if you have a reasonably large time interval. You can use 
this function to specify a custom, longer, polling time in these cases.
-}
every_ : Float -> Float -> Float -> msg -> (Float -> msg) -> AudioContext -> Sub msg
every_ pollTime interval prev noop msg context =
  Time.every pollTime (\_ ->
    let
      lookahead = 0.1
      target = prev + interval
      curr = currentTime context
      diff = target - curr
    in
      if curr >= target - lookahead then
        msg (curr + diff)
      else
        noop
  )
