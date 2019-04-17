module WebAudio.Property exposing
    ( Property(..)
    , Type(..), Label, Value(..)
    , property, audioParam, nodeProperty
    , attack, buffer, coneInnerAngle, coneOuterAngle, coneOuterGain, curve, delayTime, detune, distanceModel, fftSize, frequency, freq, gain, knee, loop, loopEnd, loopStart, maxChannelCount, maxDecibels, minDecibels, normalize, normalise, offset, orientationX, orientationY, orientationZ, oversample, pan, panningModel, playbackRate, positionX, positionY, positionZ, q, ratio, reduction, refDistance, release, rolloffFactor, smoothingTimeConstant, threshold, type_
    , encode, encodeType, encodeValue
    )

{-|


# Types

@docs Property

@docs Type, Label, Value


# Basic Constructors

@docs property, audioParam, nodeProperty


# Common Properties

@docs attack, coneInnerAngle, coneOuterAngle, coneOuterGain, curve, delayTime, detune, distanceModel, fftSize, frequency, freq, gain, knee, loop, loopEnd, loopStart, maxChannelCount, maxDecibels, minDecibels, normalize, normalise, offset, orientationX, orientationY, orientationZ, oversample, pan, panningModel, playbackRate, positionX, positionY, positionZ, q, ratio, reduction, refDistance, release, rolloffFactor, smoothingTimeConstant, threshold, type_


# JSON Encoding

@docs encode, encodeType, encodeValue

-}

import Json.Decode as Decode
import Json.Encode as Encode


{-| -}
type Property
    = Property Type Label Value


{-| -}
type Type
    = AudioParam
    | NodeProperty


{-| -}
type alias Label =
    String


{-| -}
type Value
    = BValue Bool
    | FValue Float
    | FValueList (List Float)
    | IValue Int
    | SValue String



-- Basic constructors


{-| -}
property : Type -> Label -> Value -> Property
property type__ label value =
    Property type__ label value


{-| -}
audioParam : Label -> Value -> Property
audioParam label value =
    Property AudioParam label value


{-| -}
nodeProperty : Label -> Value -> Property
nodeProperty label value =
    Property NodeProperty label value



-- Common Web Audio node properties


{-| -}
attack : Float -> Property
attack =
    FValue >> audioParam "attack"


{-| -}
buffer : List Float -> Property
buffer =
    FValueList >> nodeProperty "buffer"


{-| -}
coneInnerAngle : Float -> Property
coneInnerAngle =
    FValue >> nodeProperty "coneInnerAngle"


{-| -}
coneOuterAngle : Float -> Property
coneOuterAngle =
    FValue >> nodeProperty "coneOuterAngle"


{-| -}
coneOuterGain : Float -> Property
coneOuterGain =
    FValue >> nodeProperty "coneOuterGain"


{-| -}
curve : List Float -> Property
curve =
    FValueList >> nodeProperty "curve"


{-| -}
delayTime : Float -> Property
delayTime =
    FValue >> audioParam "delayTime"


{-| -}
detune : Float -> Property
detune =
    FValue >> audioParam "detune"


{-| -}
distanceModel : String -> Property
distanceModel =
    SValue >> nodeProperty "distanceModel"


{-| -}
fftSize : Int -> Property
fftSize =
    IValue >> nodeProperty "fftSize"


{-| -}
frequency : Float -> Property
frequency =
    FValue >> audioParam "frequency"


{-| -}
freq : Float -> Property
freq =
    frequency


{-| -}
gain : Float -> Property
gain =
    FValue >> audioParam "gain"


{-| -}
knee : Float -> Property
knee =
    FValue >> audioParam "knee"


{-| -}
loop : Bool -> Property
loop =
    BValue >> nodeProperty "loop"


{-| -}
loopEnd : Float -> Property
loopEnd =
    FValue >> nodeProperty "loopEnd"


{-| -}
loopStart : Float -> Property
loopStart =
    FValue >> nodeProperty "loopStart"


{-| -}
maxChannelCount : Int -> Property
maxChannelCount =
    IValue >> nodeProperty "maxChannelCount"


{-| -}
maxDecibels : Float -> Property
maxDecibels =
    FValue >> nodeProperty "maxDecibels"


{-| -}
minDecibels : Float -> Property
minDecibels =
    FValue >> nodeProperty "minDecibels"


{-| -}
normalize : Bool -> Property
normalize =
    BValue >> nodeProperty "normalize"


{-| -}
normalise : Bool -> Property
normalise =
    normalize


{-| -}
offset : Float -> Property
offset =
    FValue >> audioParam "offset"


{-| -}
orientationX : Float -> Property
orientationX =
    FValue >> audioParam "orientationX"


{-| -}
orientationY : Float -> Property
orientationY =
    FValue >> audioParam "orientationY"


{-| -}
orientationZ : Float -> Property
orientationZ =
    FValue >> audioParam "orientationZ"


{-| -}
oversample : String -> Property
oversample =
    SValue >> nodeProperty "oversample"


{-| -}
pan : Float -> Property
pan =
    FValue >> audioParam "pan"


{-| -}
panningModel : String -> Property
panningModel =
    SValue >> nodeProperty "panningModel"


{-| -}
playbackRate : Float -> Property
playbackRate =
    FValue >> audioParam "playbackRate"


{-| -}
positionX : Float -> Property
positionX =
    FValue >> audioParam "positionX"


{-| -}
positionY : Float -> Property
positionY =
    FValue >> audioParam "positionY"


{-| -}
positionZ : Float -> Property
positionZ =
    FValue >> audioParam "positionZ"


{-| -}
q : Float -> Property
q =
    FValue >> audioParam "q"


{-| -}
ratio : Float -> Property
ratio =
    FValue >> audioParam "ratio"


{-| -}
reduction : Float -> Property
reduction =
    FValue >> audioParam "reduction"


{-| -}
refDistance : Float -> Property
refDistance =
    FValue >> nodeProperty "refDistance"


{-| -}
release : Float -> Property
release =
    FValue >> audioParam "release"


{-| -}
rolloffFactor : Float -> Property
rolloffFactor =
    FValue >> nodeProperty "rolloffFactor"


{-| -}
smoothingTimeConstant : Float -> Property
smoothingTimeConstant =
    FValue >> nodeProperty "smoothingTimeConstant"


{-| -}
threshold : Float -> Property
threshold =
    FValue >> audioParam "threshold"


{-| -}
type_ : String -> Property
type_ =
    SValue >> nodeProperty "type"



-- Json
-- Json Encoding


{-| -}
encode : Property -> Encode.Value
encode (Property t l v) =
    Encode.object
        [ ( "type", encodeType t )
        , ( "label", Encode.string l )
        , ( "value", encodeValue v )
        ]


{-| -}
encodeType : Type -> Encode.Value
encodeType t =
    case t of
        AudioParam ->
            Encode.string "AudioParam"

        NodeProperty ->
            Encode.string "NodeProperty"


{-| -}
encodeValue : Value -> Encode.Value
encodeValue v =
    case v of
        BValue b ->
            Encode.bool b

        FValue f ->
            Encode.float f

        FValueList fs ->
            Encode.list Encode.float fs

        IValue i ->
            Encode.int i

        SValue s ->
            Encode.string s



-- Json Decoding
