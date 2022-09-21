module WebAudio.Property exposing
    ( Property, Value
    , property, audioParam
    , setValueAtTime, linearRampToValueAtTime, exponentialRampToValueAtTime
    , bool, float, floatList, int, string
    , amp, attack, coneInnerAngle, coneOuterAngle, coneOuterGain, curve
    , delayTime, detune, distanceModel, fftSize, frequency, freq, gain, knee
    , loop, loopEnd, loopStart, maxChannelCount, maxDecibels, minDecibels
    , normalize, offset, orientationX, orientationY, orientationZ, oversample
    , pan, panningModel, playbackRate, positionX, positionY, positionZ, q, ratio
    , reduction, refDistance, release, rolloffFactor, smoothingTimeConstant
    , threshold, type_
    , encode
    )

{-|


# Types

@docs Property, Value


# Basic Constructors

@docs property, audioParam
@docs setValueAtTime, linearRampToValueAtTime, exponentialRampToValueAtTime


## Primatives

@docs bool, float, floatList, int, string


# Properties

@docs amp, attack, buffer, coneInnerAngle, coneOuterAngle, coneOuterGain, curve
@docs delayTime, detune, distanceModel, fftSize, frequency, freq, gain, knee
@docs loop, loopEnd, loopStart, maxChannelCount, maxDecibels, minDecibels
@docs normalize, offset, orientationX, orientationY, orientationZ, oversample
@docs pan, panningModel, playbackRate, positionX, positionY, positionZ, q, ratio
@docs reduction, refDistance, release, rolloffFactor, smoothingTimeConstant
@docs threshold, type_


# JSON Encoding

@docs encode

-}

import Json.Encode



-- Types -----------------------------------------------------------------------


{-| Properties are how we configure the behaviour of audio nodes: things like
an oscillator's frequency or a filter's cutoff.

    import WebAudio
    import WebAudio.Property

    myOsc =
        WebAudio.oscillator
            [ WebAudio.Property.linearRampToValueAtTime 1 <|
                WebAudio.Property.frequency 880
            , WebAudio.Property.type_ "sine"
            ]
            [ WebAudio.gain
                [ WebAudio.Property.gain 0.5 ]
                [ WebAudio.audioDestination ]
            ]

This example showcases the different types of properties you can construct:

  - [`properties`](#property) like [`type_`](#type_). These are typical object
    properties that are set on the node like any other JavaScript object, and
    might be a [`bool`](#bool), [`float`](#float), [`string`](#string), etc.

  - [`audioParams`](#audioParam) like [`frequency`](#frequency) are special,
    and represent values that can be changed over time using the scheduled updates
    described below. These are always `Float`s!

  - Scheduled updates like [`linearRampToValueAtTime`](#linearRampToValueAtTime).
    These describe how a property should change over time. These scheduled updates
    only work with audio params, and not normal properties.

-}
type Property
    = NodeProperty String Value
    | AudioParam String Value
    | ScheduledUpdate
        String
        { method : ScheduledUpdateMethod
        , target : Value
        , time : Float
        }


{-| Represents a value of some property. Our audio graphs are supposed to be
_declarative_, so we don't want to be able to change the values of properties –
you'd just return a different graph with the property you wanted changed.

This type enumerates the different types of values that might be assigned to
a property like an Elm `String` or `Float`, etc.

-}
type Value
    = Value Json.Encode.Value


type ScheduledUpdateMethod
    = SetValueAtTime
    | LinearRampToValueAtTime
    | ExponentialRampToValueAtTime



-- PROPERTY CONSTRUCTORS -------------------------------------------------------


{-| Create a custom property for a node. This is like writing `node.type = 'sine'`
in JavaScript:

    import WebAudio.Property exposing (Property)

    sine : Property
    sine =
        WebAudio.Property.property "type" (WebAudio.Property.string "sine")

Ideally you'll end up using one of the predifined properties like [`type_`](#type_)
instead of this function, but it's provided in case you have custom audio nodes
with properties we might not know about.

-}
property : String -> Value -> Property
property name val =
    NodeProperty name val


{-| Create a custom audio param for a node. This is like writing
`node.frequency.value = 880` in JavaScript:

    import WebAudio.Property exposing (Property)

    middleA : Property
    middleA =
        WebAudio.Property.audioParam "frequency" 440

Ideally you'll end up using one of the predifined properties like
[`frequency`](#frequency) instead of this function, but it's provided in case you
have custom audio nodes with properties we might not know about.

-}
audioParam : String -> Float -> Property
audioParam name val =
    AudioParam name (float val)


{-| Schedule an update to a property to take place at some point in the future.
This is like writing `node.frequency.setValueAtTime(880, context.currentTime + 1)`
in JavaScript:

    import WebAudio.Property exposing (Property)

    setAfterOneSecond : Float -> Property
    setAfterOneSecond time =
        WebAudio.Property.setValueAtTime
            (time + 1)
            (WebAudio.Property.frequency 880)

❗️

-}
setValueAtTime : Float -> Property -> Property
setValueAtTime time prop =
    case prop of
        NodeProperty _ _ ->
            prop

        AudioParam label value ->
            ScheduledUpdate label
                { method = SetValueAtTime
                , target = value
                , time = time
                }

        ScheduledUpdate label { target } ->
            ScheduledUpdate label
                { method = SetValueAtTime
                , target = target
                , time = time
                }


{-| Where [`setValueAtTime`](#setValueAtTime) sets a property at a specific time,
`linearRampToValueAtTime` will smoothly ramp the property from its current value
to the target value until the given time.
-}
linearRampToValueAtTime : Float -> Property -> Property
linearRampToValueAtTime time prop =
    case prop of
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


{-| Where [`setValueAtTime`](#setValueAtTime) sets a property at a specific time,
`exponentialRampToValueAtTime` will ramp the property from its current value
to the target value until the given time using an exponential curve.

Often we perceive exponential curves as more natural than linear curves, so this
is a good choice for things like gain or frequency.

-}
exponentialRampToValueAtTime : Float -> Property -> Property
exponentialRampToValueAtTime time prop =
    case prop of
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

        ScheduledUpdate label { target } ->
            ScheduledUpdate label
                { method = ExponentialRampToValueAtTime
                , target = target
                , time = time
                }



-- Property value constructors -------------------------------------------------


{-| -}
bool : Bool -> Value
bool =
    Json.Encode.bool >> Value


{-| -}
float : Float -> Value
float =
    Json.Encode.float >> Value


{-| -}
floatList : List Float -> Value
floatList =
    Json.Encode.list Json.Encode.float >> Value


{-| -}
int : Int -> Value
int =
    Json.Encode.int >> Value


{-| -}
string : String -> Value
string =
    Json.Encode.string >> Value



-- Audio node properties -------------------------------------------------------


{-| -}
amp : Float -> Property
amp =
    audioParam "gain"


{-| -}
attack : Float -> Property
attack =
    audioParam "attack"


{-| -}
coneInnerAngle : Float -> Property
coneInnerAngle =
    float >> property "coneInnerAngle"


{-| -}
coneOuterAngle : Float -> Property
coneOuterAngle =
    float >> property "coneOuterAngle"


{-| -}
coneOuterGain : Float -> Property
coneOuterGain =
    float >> property "coneOuterGain"


{-| -}
curve : List Float -> Property
curve =
    floatList >> property "curve"


{-| -}
delayTime : Float -> Property
delayTime =
    audioParam "delayTime"


{-| -}
detune : Float -> Property
detune =
    audioParam "detune"


{-| -}
distanceModel : String -> Property
distanceModel =
    string >> property "distanceModel"


{-| -}
fftSize : Int -> Property
fftSize =
    int >> property "fftSize"


{-| -}
frequency : Float -> Property
frequency =
    audioParam "frequency"


{-| -}
freq : Float -> Property
freq =
    audioParam "frequency"


{-| -}
gain : Float -> Property
gain =
    audioParam "gain"


{-| -}
knee : Float -> Property
knee =
    audioParam "knee"


{-| -}
loop : Bool -> Property
loop =
    bool >> property "loop"


{-| -}
loopEnd : Float -> Property
loopEnd =
    float >> property "loopEnd"


{-| -}
loopStart : Float -> Property
loopStart =
    float >> property "loopStart"


{-| -}
maxChannelCount : Int -> Property
maxChannelCount =
    int >> property "maxChannelCount"


{-| -}
maxDecibels : Float -> Property
maxDecibels =
    float >> property "maxDecibels"


{-| -}
minDecibels : Float -> Property
minDecibels =
    float >> property "minDecibels"


{-| -}
normalize : Bool -> Property
normalize =
    bool >> property "normalize"


{-| -}
offset : Float -> Property
offset =
    audioParam "offset"


{-| -}
orientationX : Float -> Property
orientationX =
    audioParam "orientationX"


{-| -}
orientationY : Float -> Property
orientationY =
    audioParam "orientationY"


{-| -}
orientationZ : Float -> Property
orientationZ =
    audioParam "orientationZ"


{-| -}
oversample : String -> Property
oversample =
    string >> property "oversample"


{-| -}
pan : Float -> Property
pan =
    audioParam "pan"


{-| -}
panningModel : String -> Property
panningModel =
    string >> property "panningModel"


{-| -}
playbackRate : Float -> Property
playbackRate =
    audioParam "playbackRate"


{-| -}
positionX : Float -> Property
positionX =
    audioParam "positionX"


{-| -}
positionY : Float -> Property
positionY =
    audioParam "positionY"


{-| -}
positionZ : Float -> Property
positionZ =
    audioParam "positionZ"


{-| -}
q : Float -> Property
q =
    audioParam "q"


{-| -}
ratio : Float -> Property
ratio =
    audioParam "ratio"


{-| -}
reduction : Float -> Property
reduction =
    audioParam "reduction"


{-| -}
refDistance : Float -> Property
refDistance =
    float >> property "refDistance"


{-| -}
release : Float -> Property
release =
    audioParam "release"


{-| -}
rolloffFactor : Float -> Property
rolloffFactor =
    float >> property "rolloffFactor"


{-| -}
smoothingTimeConstant : Float -> Property
smoothingTimeConstant =
    float >> property "smoothingTimeConstant"


{-| -}
threshold : Float -> Property
threshold =
    audioParam "threshold"


{-| -}
type_ : String -> Property
type_ =
    string >> property "type"



-- JSON encoding ---------------------------------------------------------------


{-| -}
encode : Property -> Json.Encode.Value
encode prop =
    case prop of
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
        , ( "target"
          , case target of
                Value value ->
                    value
          )
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
