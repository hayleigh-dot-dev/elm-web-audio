module WebAudio.Property exposing
  ( Property, Value
  , nodeProperty, audioParam
  , bool, float, floatList, int, string
  , setValueAtTime, linearRampToValueAtTime, exponentialRampToValueAtTime
  , attack, buffer, coneInnerAngle, coneOuterAngle, coneOuterGain, curve, delayTime, detune, distanceModel, fftSize, frequency, gain, knee, loop, loopEnd, loopStart, maxChannelCount, maxDecibels, minDecibels, normalize, offset, orientationX, orientationY, orientationZ, oversample, pan, panningModel, playbackRate, positionX, positionY, positionZ, q, ratio, reduction, refDistance, release, rolloffFactor, smoothingTimeConstant, threshold, type_
  , encode
  )

{-|

# Types
@docs Property, Value

# Basic Constructors
@docs nodeProperty, audioParam

## Primatives
@docs bool, float, floatList, int, string

## Scheduled Audio Params
@docs setValueAtTime, linearRampToValueAtTime, exponentialRampToValueAtTime

# Properties
@docs attack, buffer, coneInnerAngle, coneOuterAngle, coneOuterGain, curve, delayTime, detune, distanceModel, fftSize, frequency, gain, knee, loop, loopEnd, loopStart, maxChannelCount, maxDecibels, minDecibels, normalize, offset, orientationX, orientationY, orientationZ, oversample, pan, panningModel, playbackRate, positionX, positionY, positionZ, q, ratio, reduction, refDistance, release, rolloffFactor, smoothingTimeConstant, threshold, type_

# JSON Encoding
@docs encode

-}

import Json.Encode

-- Types -----------------------------------------------------------------------
{-| A type to encapsulate all the different properties that can exist on a Web
Audio node. This could be something like an oscillator's frequency, whether an
audio buffer is set to loop, or whether a filter is a highpass or a lowpass
filter.


The implementation is currently concealled because I don't *think* it is necessary 
to distinguish between the different types of Property when developing.
-}
type Property
  = NodeProperty String Value
  | AudioParam String Value
  | ScheduledUpdate String
      { method : ScheduledUpdateMethod
      , target : Value
      , time : Float
      }

{-| Properties can have different types of value, for example the frequency 
property of an oscillator is a `Float` but its type property is a `String`. To
capture all these posibilities we have a special Value type.

See the Primatives section below for functions create Values yourself. This is
only necessary if you're creating a Property manually because you're using some
custom audio nodes or you can't find a Property below.

> *Note: If you can't find a Property but it's exists on a standard Web Audio node,
consider submitting an issue or a pull request to add it!*
-}
type Value =
  Value Json.Encode.Value

type ScheduledUpdateMethod
  = SetValueAtTime
  | LinearRampToValueAtTime
  | ExponentialRampToValueAtTime

-- Property value constructors -------------------------------------------------
{-| Convert a `Bool` to a Property value.

    import WebAudio.Property exposing (nodeProperty, bool)

    nodeProperty "loop" (bool True)
-}
bool : Bool -> Value
bool =
  Json.Encode.bool >> Value

{-| Convert a `Float` to a Property value.

    import WebAudio.Property exposing (audioParam, float)

    audioParam "detune" (float 0.2)
-}
float : Float -> Value
float =
  Json.Encode.float >> Value

{-| Convert a list of `Float`s to a Property value.

    import WebAudio.Property exposing (nodeProperty, floatList)

    nodeProperty "buffer" (floatList [0, 0.5, 1, 0.5, 0, -0.5, -1])
-}
floatList : List Float -> Value
floatList =
  Json.Encode.list Json.Encode.float >> Value

{-| Convert an `Int` to a Property value.

    import WebAudio.Property exposing (nodeProperty, int)

    nodeProperty "fftSize" (int 512)
-}
int : Int -> Value
int =
  Json.Encode.int >> Value

{-| Convert a `String` to a Property value.

    import WebAudio.Property exposing (nodeProperty, string)

    nodeProperty "type" (string "triangle")
-}
string : String -> Value
string =
  Json.Encode.string >> Value

-- Property constructors -------------------------------------------------------
{-| 

> *Note: It is rare to need to create your own properties in this way.*
-}
nodeProperty : String -> Value -> Property
nodeProperty =
  NodeProperty

{-| 

> *Node: It is rare to need to create your own properties in this way.*
-}
audioParam : String -> Value -> Property
audioParam =
  AudioParam

{-| Schedule an update to a property to take place at some point in the future.

    import WebAudio.Property exposing (setValueAtTime, frequency)

    setValueAtTime (frequency 440) 1

It's important to note that `1` refers to one second after an Audio Context has
started, **not** one second from *now*. This is best used once you have the
[current time](/WebAudio.Context#currentTime) from an existing Audio Context.
-}
setValueAtTime : Property -> Float -> Property
setValueAtTime property time =
  case property of
  NodeProperty _ _ ->
    property

  AudioParam label value ->
    ScheduledUpdate label
      { method = SetValueAtTime
      , target = value
      , time = time
      }

  ScheduledUpdate label { method, target } ->
    ScheduledUpdate label
      { method = SetValueAtTime
      , target = target
      , time = time
      }

{-| Schedule a linear ramp of a property value from now untl some point in the
future.

    import WebAudio.Property exposing (linearRampToValueAtTime, frequency)

    linearRampToValueAtTime (frequency 440) 1

It's important to note that `1` refers to one second after an Audio Context has
started, **not** one second from *now*. This is best used once you have the
[current time](/WebAudio.Context#currentTime) from an existing Audio Context.
-}
linearRampToValueAtTime : Property -> Float -> Property
linearRampToValueAtTime property time =
  case property of
    NodeProperty label value ->
      ScheduledUpdate label
        { method = LinearRampToValueAtTime
        , target = value
        , time = time
        }

    AudioParam label value ->
      ScheduledUpdate label
        { method = LinearRampToValueAtTime
        , target = value
        , time = time
        }

    ScheduledUpdate label { method, target } ->
      ScheduledUpdate label
        { method = LinearRampToValueAtTime
        , target = target
        , time = time
        }

{-| Schedule an exponential ramp of a property value from now untl some point in the
future. Try to make sure the value is non-zero!

    import WebAudio.Property exposing (exponentialRampToValueAtTime, frequency)

    exponentialRampToValueAtTime (frequency 440) 1

It's important to note that `1` refers to one second after an Audio Context has
started, **not** one second from *now*. This is best used once you have the
[current time](/WebAudio.Context#currentTime) from an existing Audio Context.
-}
exponentialRampToValueAtTime : Property -> Float -> Property
exponentialRampToValueAtTime property time =
  case property of
    NodeProperty label value ->
      ScheduledUpdate label
        { method = ExponentialRampToValueAtTime
        , target = value
        , time = time
        }

    AudioParam label value ->
      ScheduledUpdate label
        { method = ExponentialRampToValueAtTime
        , target = value
        , time = time
        }

    ScheduledUpdate label { method, target } ->
      ScheduledUpdate label
        { method = ExponentialRampToValueAtTime
        , target = target
        , time = time
        }

-- Audio node properties -------------------------------------------------------
{-| Defines the time in seconds it takes to reduce a signal by 10dB in a 
dynamicsCompressor node. If unset, this property defaults to 0.03.

Nodes that use this property:
- dynamicsCompressor

Expected range:
- min: `0`
- max: `1`

-}
attack : Float -> Property
attack =
  float >> audioParam "attack"

{-| A list of samples making up a short audio clip. Due to current limitations
with the elm-web-audio api, only *single channel* buffers are supported.

Nodes that use this property:
- audioBufferSource
- convolver

Expected range:
- min: `-1`
- max: `1`
-}
buffer : List Float -> Property
buffer =
  floatList >> nodeProperty "buffer"

{-| The angle, in degrees, of a cone in which there will be no volume reduction.

Nodes that use this property:
- panner

Expected range:
- min: `0`
- max: `360`

See https://developer.mozilla.org/en-US/docs/Web/API/PannerNode for more
information.
-}
coneInnerAngle : Float -> Property
coneInnerAngle =
  float >> nodeProperty "coneInnerAngle"

{-| The angle, in degrees, of a cone outside of which the volume will be reduced
by a constant value (set by coneOuterGain).

Nodes that use this property:
- panner

Expected range:
- min: `0`
- max: `360`

See https://developer.mozilla.org/en-US/docs/Web/API/PannerNode for more
information.
-}
coneOuterAngle : Float -> Property
coneOuterAngle =
  float >> nodeProperty "coneOuterAngle"

{-| The amount of volume reduction to be applied outside of the cone defined by
coneOuterAngle.

Nodes that use this property:
- panner

Expected range:
- min: `0`
- max: `1`

See https://developer.mozilla.org/en-US/docs/Web/API/PannerNode for more
information.
-}
coneOuterGain : Float -> Property
coneOuterGain =
  float >> nodeProperty "coneOuterGain"

{-| A list that describes the distortion curve to apply to the signal. The first
element of the list is applied to signal values of -1, the last element of the
list is applied to signal values of 1, and the mid-point in the list is applied
to signal values of 0. When there are more than three items in the list, linear
interpolation is performed.

Nodes that use this property:
- waveShaper

See https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode for more
information.
-}
curve : List Float -> Property
curve =
  floatList >> nodeProperty "curve"

{-| The amount of delay to apply, in seconds, to an incoming signal. 

Nodes that use this property:
- delay

Expected range:
- min: `0`
- max: see below...

Note: Currently, when **first** creating a new delay node, the delayTime
property will *also* be used to specify the *maximum possible delay time* for
that node. The issue tracker can be found here:
https://github.com/pd-andy/elm-web-audio/issues/7
-}
delayTime : Float -> Property
delayTime =
  float >> audioParam "delayTime"

{-| The amount, in cents, to detune the pitch of a signal. 100 cents corresponds
to a pitch shift *up* of one semitone.

Nodes that use this property:
- audioBufferSource
- oscillator
-}
detune : Float -> Property
detune =
  float >> audioParam "detune"

{-| The algorithm used to determine how the volume of a signal is reduced as it
is moved away from a listener.

Nodes that use this property:
- panner

Expected values:
- "linear"
- "inverse"
- "exponential"

See https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/distanceModel
for more information on each algorithm.
-}
distanceModel : String -> Property
distanceModel =
  string >> nodeProperty "distanceModel"

{-| The size of the FFT window used by an analyser node. Must be a power of two.

Nodes that use this property:
- analyser (currently unsuported by elm-web-audio)

Expected values:
- `32`
- `64`
- `128`
- `256`
- `512`
- `1024`
- `2048`
- `4096`
- `8192`
- `16384`
- `32768`
-}
fftSize : Int -> Property
fftSize =
  int >> nodeProperty "fftSize"

{-| -}
frequency : Float -> Property
frequency =
  float >> audioParam "frequency"

{-| -}
gain : Float -> Property
gain =
  float >> audioParam "gain"

{-| -}
knee : Float -> Property
knee =
  float >> audioParam "knee"

{-| -}
loop : Bool -> Property
loop =
  bool >> nodeProperty "loop"

{-| -}
loopEnd : Float -> Property
loopEnd =
  float >> nodeProperty "loopEnd"

{-| -}
loopStart : Float -> Property
loopStart =
  float >> nodeProperty "loopStart"

{-| -}
maxChannelCount : Int -> Property
maxChannelCount =
  int >> nodeProperty "maxChannelCount"

{-| -}
maxDecibels : Float -> Property
maxDecibels =
  float >> nodeProperty "maxDecibels"

{-| -}
minDecibels : Float -> Property
minDecibels =
  float >> nodeProperty "minDecibels"

{-| -}
normalize : Bool -> Property
normalize =
  bool >> nodeProperty "normalize"

{-| -}
offset : Float -> Property
offset =
  float >> audioParam "offset"

{-| -}
orientationX : Float -> Property
orientationX =
  float >> audioParam "orientationX"

{-| -}
orientationY : Float -> Property
orientationY =
  float >> audioParam "orientationY"

{-| -}
orientationZ : Float -> Property
orientationZ =
  float >> audioParam "orientationZ"

{-| -}
oversample : String -> Property
oversample =
  string >> nodeProperty "oversample"

{-| -}
pan : Float -> Property
pan =
  float >> audioParam "pan"

{-| -}
panningModel : String -> Property
panningModel =
  string >> nodeProperty "panningModel"

{-| -}
playbackRate : Float -> Property
playbackRate =
  float >> audioParam "playbackRate"

{-| -}
positionX : Float -> Property
positionX =
  float >> audioParam "positionX"

{-| -}
positionY : Float -> Property
positionY =
  float >> audioParam "positionY"

{-| -}
positionZ : Float -> Property
positionZ =
  float >> audioParam "positionZ"

{-| -}
q : Float -> Property
q =
  float >> audioParam "q"

{-| -}
ratio : Float -> Property
ratio =
  float >> audioParam "ratio"

{-| -}
reduction : Float -> Property
reduction =
  float >> audioParam "reduction"

{-| -}
refDistance : Float -> Property
refDistance =
  float >> nodeProperty "refDistance"

{-| -}
release : Float -> Property
release =
  float >> audioParam "release"

{-| -}
rolloffFactor : Float -> Property
rolloffFactor =
  float >> nodeProperty "rolloffFactor"

{-| -}
smoothingTimeConstant : Float -> Property
smoothingTimeConstant =
  float >> nodeProperty "smoothingTimeConstant"

{-| -}
threshold : Float -> Property
threshold =
  float >> audioParam "threshold"

{-| -}
type_ : String -> Property
type_ =
  string >> nodeProperty "type"

-- JSON encoding ---------------------------------------------------------------
{-| -}
encode : Property -> Json.Encode.Value
encode property =
  case property of
  NodeProperty label (Value value) ->
    Json.Encode.object
      [ ( "type", Json.Encode.string "NodeProperty" )
      , ( "label", Json.Encode.string label )
      , ( "value", value )
      ]

  AudioParam label (Value value) ->
    Json.Encode.object
      [ ( "type", Json.Encode.string "AudioParam" )
      , ( "label", Json.Encode.string label )
      , ( "value", value )
      ]

  ScheduledUpdate label value ->
    Json.Encode.object
      [ ( "type", Json.Encode.string "ScheduledUpdate" )
      , ( "label", Json.Encode.string label )
      , ( "value", encodeScheduledUpdateValue value )
      ]

encodeScheduledUpdateValue : { method : ScheduledUpdateMethod, target : Value, time : Float } -> Json.Encode.Value
encodeScheduledUpdateValue { method, target, time } =
  Json.Encode.object
    [ ( "method", encodeScheduledUpdateMethod method )
    , ( "target", case target of (Value value) -> value )
    , ( "time", Json.Encode.float time )
    ]

encodeScheduledUpdateMethod : ScheduledUpdateMethod -> Json.Encode.Value
encodeScheduledUpdateMethod method =
  case method of
  SetValueAtTime ->
    Json.Encode.string "setValueAtTime"

  LinearRampToValueAtTime ->
    Json.Encode.string "linearRampToValueAtTime"

  ExponentialRampToValueAtTime ->
    Json.Encode.string "exponentialRampToValueAtTime"
