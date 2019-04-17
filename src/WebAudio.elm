module WebAudio exposing
    ( Node(..)
    , Type, Key
    , node, ref, key
    , analyser, audioBufferSource, audioDestination, biquadFilter, channelMerger, channelSplitter, constantSource, convolver, dac, delay, dynamicsCompressor, gain, iirFilter, oscillator, osc, panner, stereoPanner, waveShaper
    , encode
    )

{-|


# Types

@docs Node

@docs Type, Key


# Basic Constructors

@docs node, ref, key


# Web Audio Nodes

@docs analyser, audioBufferSource, audioDestination, biquadFilter, channelMerger, channelSplitter, constantSource, convolver, dac, delay, dynamicsCompressor, gain, iirFilter, oscillator, osc, panner, stereoPanner, waveShaper


# JSON Encoding

@docs encode

-}

import Json.Decode as Decode
import Json.Encode as Encode exposing (encode)
import WebAudio.Property as Property exposing (..)


{-| The core building block of any Web Audio signal
graph. `Keyed` nodes are just like regular nodes but
with an additonal `Key` property. This allows `Ref` nodes
to reference them elsewhere in the graph!
-}
type Node
    = Node Type (List Property) (List Node)
    | Keyed Key Type (List Property) (List Node)
    | Ref Key


{-| A simple type alias representing the type of `Node`. This
could be something like "OscillatorNode" or "RefNode".
-}
type alias Type =
    String


{-| A simple type alias representing unique key used to identify
nodes. Use `Key`s like you would use the `id` attribute on a HTML
element.
-}
type alias Key =
    String


{-| General way to construct Web Audio nodes. This is used
to create all the helper functions below. You can use this
function to define custom nodes by partially applying just
the `type` parameter. This is handy if you're using a
library like Tone.js and want to use those nodes in Elm.

    omniOscillator : List Property -> List Node -> Node
    omniOscillator =
        node "Tone-OmniOscillatorNode"

    myOsc =
        omniOscillator
            [ Property.freq 440 ]
            [ dac ]

-}
node : Type -> List Property -> List Node -> Node
node =
    Node


{-| A ref node is used to refer to a keyed node elsewhere in
the graph. This is how we connect multiple "chains" of nodes
together and represet a graph in a simple list.
-}
ref : Key -> Node
ref =
    Ref


{-| Use this function to apply a key to a node. In the case
of already keyed nodes, or ref nodes, this will update the
key to the new value.

    a = osc [ Property.freq 440 ] [ dac ]
    b = keyedGain "b" [ Property.gain 0.5 ] [ dac ]
    c = ref "b"

    key a "myOsc" -- Give a the key "myOsc"
    key b "myGain" -- Rename b's key to "myGain"
    key c "myOsc" -- c is now a RefNode to "myOsc"

-}
key : Key -> Node -> Node
key k n =
    case n of
        Node t ps cs ->
            Keyed k t ps cs

        Keyed _ t ps cs ->
            Keyed k t ps cs

        Ref _ ->
            Ref k


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode>
-}
analyser : List Property -> List Node -> Node
analyser =
    Node "AnalyserNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode>
-}
audioBufferSource : List Property -> List Node -> Node
audioBufferSource =
    Node "AudioBufferSourceNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/AudioDestinationNode>
-}
audioDestination : Node
audioDestination =
    Node "AudioDestinationNode" [] []


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode>
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


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode>
-}
constantSource : List Property -> List Node -> Node
constantSource =
    Node "ConstantSource"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode>
-}
convolver : List Property -> List Node -> Node
convolver =
    Node "ConvolverNode"


{-| An alias for `audioDestination`.
-}
dac : Node
dac =
    audioDestination


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/DelayNode>
-}
delay : List Property -> List Node -> Node
delay =
    Node "DelayNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode>
-}
dynamicsCompressor : List Property -> List Node -> Node
dynamicsCompressor =
    Node "DynamicsCompressorNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/GainNode>
-}
gain : List Property -> List Node -> Node
gain =
    Node "GainNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/>
-}
iirFilter : List Property -> List Node -> Node
iirFilter =
    Node "IIRFilterNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode>
-}
oscillator : List Property -> List Node -> Node
oscillator =
    Node "OscillatorNode"


{-| An alias for `oscillator`.
-}
osc : List Property -> List Node -> Node
osc =
    oscillator


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/PannerNode>
-}
panner : List Property -> List Node -> Node
panner =
    Node "PannerNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/StereoPannerNode>
-}
stereoPanner : List Property -> List Node -> Node
stereoPanner =
    Node "StereoPannerNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode>
-}
waveShaper : List Property -> List Node -> Node
waveShaper =
    Node "WaveShaperNode"



-- Json
-- Json Encoding


{-| Converts a `Node` into a Json value. Use this to send a node through
a port to javascipt, where it can be constructed into a Web Audio node!
-}
encode : Node -> Encode.Value
encode n =
    case n of
        Node t ps cs ->
            Encode.object
                [ ( "type", Encode.string t )
                , ( "properties", Encode.list Property.encode ps )
                , ( "connections", Encode.list encode cs )
                ]

        Keyed k t ps cs ->
            Encode.object
                [ ( "key", Encode.string k )
                , ( "type", Encode.string t )
                , ( "properties", Encode.list Property.encode ps )
                , ( "connections", Encode.list encode cs )
                ]

        Ref k ->
            Encode.object
                [ ( "key", Encode.string k )
                , ( "type", Encode.string "RefNode" )
                ]



-- Json Decoding
