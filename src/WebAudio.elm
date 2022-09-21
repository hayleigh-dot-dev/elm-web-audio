module WebAudio exposing
    ( Node
    , node, ref, keyed, param
    , oscillator, osc, gain, audioDestination, dac, delay
    , channelMerger, channelSplitter, constantSource
    , biquadFilter, convolver, dynamicsCompressor, iirFilter, panner
    , stereoPanner, waveShaper
    , encode
    )

{-|


# Types

@docs Node


# Basic Constructors

@docs node, ref, keyed, param


# Web Audio Nodes


## Common audio nodes

@docs oscillator, osc, gain, audioDestination, dac, delay


## Utility nodes

@docs channelMerger, channelSplitter, constantSource


## Signal processing nodes

@docs biquadFilter, convolver, dynamicsCompressor, iirFilter, panner
@docs stereoPanner, waveShaper


## JSON Encoding

@docs encode

-}

-- Imports ---------------------------------------------------------------------

import Json.Encode
import WebAudio.Property exposing (Property)



-- Types -----------------------------------------------------------------------


{-| Represents a node in an audio processing singal graph. There are a handful
of basic constructors: [`node`](#node) for creating typical audio nodes,
[`keyed`](#keyed) for attaching a key or id to an existing node, and [`ref`](#ref)
for referencing a node elsewhere in the graph by id.

There are also a number of constructors for specific audio nodes, such as
[`oscillator`](#oscillator) and [`gain`](#gain). These constructors mirror the
low-level nodes provided by the Web Audio API: they make great building blocks!

    import WebAudio
    import WebAudio.Property

    synth : Float -> Float -> List WebAudio.Node -> WebAudio.Node
    synth freq gain connections =
        WebAudio.oscillator
            [ WebAudio.Parameters.frequency freq ]
            [ WebAudio.gain
                [ WebAudio.Parameters.gain gain ]
                connections
            ]

-}
type Node
    = Node String (List Property) (List Node)
    | Keyed String String (List Property) (List Node)
    | Ref String



-- Node constructors -----------------------------------------------------------


{-| The most general way to construct Web Audio nodes. This is used to create all
the helper functions below.

You can use this function to define custom nodes by partially applying just the
`type` parameter. This is handy if you're using a library like Tone.js and want
to use those nodes in Elm.

    import WebAudio
    import WebAudio.Property exposing (Property)

    omniOscillator : List Property -> List WebAudio.Node -> WebAudio.Node
    omniOscillator =
        WebAudio.node "Tone-OmniOscillatorNode"

    myOsc : WebAudio.Node
    myOsc =
        omniOscillator
            [ WebAudio.Property.frequency 440 ]
            [ WebAudio.dac ]

-}
node : String -> List Property -> List Node -> Node
node =
    Node


{-| A ref node is used to refer to some other audio node by id. We can do things
like create a feedback loop by connecting a node back into itself.

    import WebAudio
    import WebAudio.Property exposing (Property)

    feedbackDelay : Float -> Float -> List WebAudio.Node -> WebAudio.Node
    feedbackDelay amount time connections =
        WebAudio.keyed "feedback-delay" <|
            WebAudio.delay
                [ WebAudio.Property.delayTime time ]
                [ WebAudio.gain
                    [ WebAudio.Property.gain gain ]
                    -- Reference the delay node above by its key. This sends
                    -- the output of the gain node back into the delay node,
                    -- creating a feedback loop!
                    (WebAudio.ref "feedback-delay" :: connections)
                ]

    synth : Float -> Float -> WebAudio.Node
    synth freq gain =
        WebAudio.oscillator
            [ WebAudio.Parameters.frequency freq ]
            [ WebAudio.gain
                [ WebAudio.Parameters.gain gain ]
                [ feedbackDelay 0.45 250 <|
                    [ WebAudio.dac ]
                ]
            ]

-}
ref : String -> Node
ref =
    Ref


{-| Attach a key or id to an existing node. This is commonly used in conjunction
with [`ref`](#ref) nodes to create feedback loops and other more complex signal
graphs.
-}
keyed : String -> Node -> Node
keyed k n =
    case n of
        Node t ps cs ->
            Keyed k t ps cs

        Keyed _ t ps cs ->
            Keyed k t ps cs

        Ref _ ->
            Ref k


{-| Typically we chain audio nodes together either implicitly by nesting them or
explicitly by using [`ref`](#ref) nodes but there is a third way to connect
audio nodes: by connecting them to certain audio params!

This is useful for common synthesis techniques like AM and FM synthesis, or
modulating parameters like cutoff frequencer of a filter using an oscillator.

    import WebAudio
    import WebAudio.Property

    audio : List WebAudio.Node
    audio =
        [ WebAudio.oscillator
            [ WebAudio.Property.frequency 5 ]
            -- Connect to the "frequency" parameter of the "carrier" node
            [ WebAudio.param "carrier" "frequency" ]
        , WebAudio.keyed "carrier" <|
            WebAudio.oscillator []
                [ WebAudio.dac ]
        ]

-}
param : String -> String -> Node
param k p =
    ref (k ++ "." ++ p)



-- Audio nodes -----------------------------------------------------------------


{-| The audio destination is... the destination of our audio! Connect to this
node to get sound coming out of your speakers.

It doesn't have any parameters itself, and it doesn't make sense to connect
the destination to anything else; it's the end of the line.

    import WebAudio
    import WebAudio.Property

    audio : List WebAudio.Node
    audio =
        [ WebAudio.oscillator
            [ WebAudio.Property.frequency 440 ]
            [ WebAudio.audioDestination ]
        ]

See: <https://developer.mozilla.org/en-US/docs/Web/API/AudioDestinationNode>

-}
audioDestination : Node
audioDestination =
    Node "AudioDestinationNode" [] []


{-| Common properties:

  - [`frequency`](./WebAudio-Property#frequency)
  - [`detune`](./WebAudio-Property#detune)
  - [`q`](./WebAudio-Property#q)
  - [`gain`](./WebAudio-Property#gain)

See: <https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode>

-}
biquadFilter : List Property -> List Node -> Node
biquadFilter =
    Node "BiquadFilterNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ChannelMergerNode>
-}
channelMerger : List Property -> List Node -> Node
channelMerger =
    Node "ChannelMergerNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ChanneSplliterNode>
-}
channelSplitter : List Property -> List Node -> Node
channelSplitter =
    Node "ChannelSplitterNode"


{-| Common properties:

  - [`offset`](./WebAudio-Property#offset)

See: <https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode>

-}
constantSource : List Property -> List Node -> Node
constantSource =
    Node "ConstantSource"


{-| Common properties:

  - [`buffer`](./WebAudio-Property#buffer)
  - [`normalise`](./WebAudio-Property#normalise) | [`normalize`](./WebAudio-Property#normalize)

See: <https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode>

-}
convolver : List Property -> List Node -> Node
convolver =
    Node "ConvolverNode"


{-| An alias for `audioDestination`. "dac" is another common name for an output:
it stands for _digital to analog converter_.
-}
dac : Node
dac =
    audioDestination


{-| Common properties:

  - [`delayTime`](./WebAudio-Property#delayTime)

See: <https://developer.mozilla.org/en-US/docs/Web/API/DelayNode>

-}
delay : List Property -> List Node -> Node
delay =
    Node "DelayNode"


{-| Common properties:

  - [`threshold`](./WebAudio-Property#threshold)
  - [`knee`](./WebAudio-Property#knee)
  - [`ratio`](./WebAudio-Property#ratio)
  - [`reduction`](./WebAudio-Property#reduction)
  - [`attack`](./WebAudio-Property#attack)
  - [`release`](./WebAudio-Property#release)

See: <https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode>

-}
dynamicsCompressor : List Property -> List Node -> Node
dynamicsCompressor =
    Node "DynamicsCompressorNode"


{-| Common properties:

  - [`gain`](./WebAudio-Property#gain)

See: <https://developer.mozilla.org/en-US/docs/Web/API/GainNode>

-}
gain : List Property -> List Node -> Node
gain =
    Node "GainNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/>
-}
iirFilter : List Property -> List Node -> Node
iirFilter =
    Node "IIRFilterNode"


{-| Common properties:

  - [`frequency`](./WebAudio-Property#frequency)
  - [`detune`](./WebAudio-Property#detune)
  - [`type`](./WebAudio-Property#type)

See: <https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode>

-}
oscillator : List Property -> List Node -> Node
oscillator =
    Node "OscillatorNode"


{-| An alias for [`oscillator`](#oscillator).

It turns out oscillators are pretty common in lots of audio signal graphs. It
also turns out that "oscillator" is a pretty long word, so you can use `osc`
instead to save your fingers and your eyes.

-}
osc : List Property -> List Node -> Node
osc =
    oscillator


{-| Common properties:

  - [`coneInnerAngle`](./WebAudio-Property#coneInnerAngle)
  - [`coneOuterAngle`](./WebAudio-Property#coneOuterAngle)
  - [`coneOuterGain`](./WebAudio-Property#coneOuterGain)
  - [`distanceModel`](./WebAudio-Property#distanceModel)
  - [`maxDistance`](./WebAudio-Property#maxDistance)
  - [`orientationX`](./WebAudio-Property#orientationX)
  - [`orientationY`](./WebAudio-Property#orientationY)
  - [`orientationZ`](./WebAudio-Property#orientationZ)
  - [`panningModel`](./WebAudio-Property#panningModel)
  - [`positionX`](./WebAudio-Property#positionX)
  - [`positionY`](./WebAudio-Property#positionY)
  - [`positionZ`](./WebAudio-Property#positionZ)
  - [`refDistance`](./WebAudio-Property#refDistance)
  - [`rolloffFactor`](./WebAudio-Property#rolloffFactor)

See: <https://developer.mozilla.org/en-US/docs/Web/API/PannerNode>

-}
panner : List Property -> List Node -> Node
panner =
    Node "PannerNode"


{-| Common properties:

  - [`pan`](./WebAudio-Property#pan)

See: <https://developer.mozilla.org/en-US/docs/Web/API/StereoPannerNode>

-}
stereoPanner : List Property -> List Node -> Node
stereoPanner =
    Node "StereoPannerNode"


{-| Common properties:

  - [`curve`](./WebAudio-Property#curve)
  - [`oversample`](./WebAudio-Property#oversample)

See: <https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode>

-}
waveShaper : List Property -> List Node -> Node
waveShaper =
    Node "WaveShaperNode"



-- JSON ENCODING ---------------------------------------------------------------


{-| Converts a `Node` into a value we can through a port to some JavaScript that
can actually convert our signal graph into Web Audio code.

You could also go on to seriliase the graph with `Json.Encode.encode` and send
it to a server, store it in LocalStorage, or other fun things.

-}
encode : Node -> Json.Encode.Value
encode n =
    case n of
        Node t ps cs ->
            Json.Encode.object
                [ ( "type", Json.Encode.string t )
                , ( "properties", Json.Encode.list WebAudio.Property.encode ps )
                , ( "connections", Json.Encode.list encode cs )
                ]

        Keyed k t ps cs ->
            Json.Encode.object
                [ ( "key", Json.Encode.string k )
                , ( "type", Json.Encode.string t )
                , ( "properties", Json.Encode.list WebAudio.Property.encode ps )
                , ( "connections", Json.Encode.list encode cs )
                ]

        Ref k ->
            Json.Encode.object
                [ ( "key", Json.Encode.string k )
                , ( "type", Json.Encode.string "RefNode" )
                ]
