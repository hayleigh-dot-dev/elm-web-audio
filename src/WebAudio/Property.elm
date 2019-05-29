module WebAudio.Property exposing (..)


import Json.Encode


{-| -}
type Property
  = NodeProperty String Value
  | AudioParam String Value
  | ScheduledUpdate String 
    { method : ScheduledUpdateMethod
    , target : Value
    , time : Float
    }


{-| -}
type alias Value = Json.Encode.Value


type ScheduledUpdateMethod
  = SetValueAtTime
  | LinearRampToValueAtTime
  | ExponentialRampToValueAtTime


{-| -}
bool : Bool -> Value
bool =
  Json.Encode.bool


{-| -}
float : Float -> Value
float =
  Json.Encode.float


{-| -}
floatList : List Float -> Value
floatList =
  Json.Encode.list Json.Encode.float


{-| -}
int : Int -> Value
int = 
  Json.Encode.int


{-| -}
string : String -> Value
string =
  Json.Encode.string


{-| -}
nodeProperty : String -> Value -> Property
nodeProperty =
  NodeProperty


{-| -}
audioParam : String -> Value -> Property
audioParam =
  AudioParam 


{-| -}
setValueAtTime : Property -> Float -> Property
setValueAtTime property time =
  case property of
    NodeProperty label value ->
      ScheduledUpdate label 
        { method = SetValueAtTime
        , target = value
        , time = time
        }

    AudioParam label value ->
      ScheduledUpdate label
        { method = SetValueAtTime
        , target = value
        , time = time
        }

    ScheduledUpdate _ _ ->
      property


{-| -}
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

    ScheduledUpdate _ _ ->
      property


{-| -}
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

    ScheduledUpdate _ _ ->
      property


{-| -}
attack : Float -> Property
attack =
    float >> audioParam "attack"


{-| -}
buffer : List Float -> Property
buffer =
    floatList >> nodeProperty "buffer"


{-| -}
coneInnerAngle : Float -> Property
coneInnerAngle =
    float >> nodeProperty "coneInnerAngle"


{-| -}
coneOuterAngle : Float -> Property
coneOuterAngle =
    float >> nodeProperty "coneOuterAngle"


{-| -}
coneOuterGain : Float -> Property
coneOuterGain =
    float >> nodeProperty "coneOuterGain"


{-| -}
curve : List Float -> Property
curve =
    floatList >> nodeProperty "curve"


{-| -}
delayTime : Float -> Property
delayTime =
    float >> audioParam "delayTime"


{-| -}
detune : Float -> Property
detune =
    float >> audioParam "detune"


{-| -}
distanceModel : String -> Property
distanceModel =
    string >> nodeProperty "distanceModel"


{-| -}
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


{-| -}
encode : Property -> Value
encode property =
  case property of
    NodeProperty label value ->
      Json.Encode.object
        [ ("type", Json.Encode.string "NodeProperty")
        , ("label", Json.Encode.string label)
        , ("value", value)
        ]

    AudioParam label value ->
      Json.Encode.object
        [ ("type", Json.Encode.string "AudioParam")
        , ("label", Json.Encode.string label)
        , ("value", value)
        ]


    ScheduledUpdate label value ->
      Json.Encode.object
        [ ("type", Json.Encode.string "ScheduledUpdate")
        , ("label", Json.Encode.string label)
        , ("value", encodeScheduledUpdateValue value)
        ]


encodeScheduledUpdateValue : { method : ScheduledUpdateMethod, target : Value, time : Float } -> Value
encodeScheduledUpdateValue { method, target, time } =
  Json.Encode.object
    [ ("method", encodeScheduledUpdateMethod method)
    , ("target", target)
    , ("time", Json.Encode.float time)
    ]


encodeScheduledUpdateMethod : ScheduledUpdateMethod -> Value
encodeScheduledUpdateMethod method =
  case method of
    SetValueAtTime ->
      Json.Encode.string "setValueAtTime"

    LinearRampToValueAtTime ->
      Json.Encode.string "linearRampToValueAtTime"

    ExponentialRampToValueAtTime ->
      Json.Encode.string "exponentialRampToValueAtTime"