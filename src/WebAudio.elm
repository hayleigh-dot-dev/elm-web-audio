module WebAudio exposing
    ( Node, Type, Key, Graph
    , node, ref, key
    , oscillator, osc, gain, audioDestination, dac, audioBufferSource, delay
    , channelMerger, channelSplitter, constantSource
    , biquadFilter, convolver, dynamicsCompressor, iirFilter, panner, stereoPanner, waveShaper
    , encode, encodeGraph
    )

{-|
# Types
@docs Node, Type, Key, Graph

# Basic Constructors
@docs node, ref, key

# Web Audio Nodes
## Common audio nodes
@docs oscillator, osc, gain, audioDestination, dac, audioBufferSource, delay

## Utility nodes
@docs channelMerger, channelSplitter, constantSource

## Signal processing nodes
@docs biquadFilter, convolver, dynamicsCompressor, iirFilter, panner, stereoPanner, waveShaper

# JSON Encoding
To turn the json in Web Audio nodes, you need to know what that data looks like.
Here's a breakdown of how everything is encoded:

**Node:**

```json
{
    "type": "OscillatorNode",
    "properties": [
        ...
    ],
    "connections": [
        ...
    ]
}
```

**Keyed:**

```json
{
    "key": "myOsc",
    "type": "OscillatorNode",
    "properties": [
        ...
    ],
    "connections": [
        ...
    ]
}
```

**Ref:**

```json
{
    "key": "myOsc",
    "type": "RefNode"
}
```

Properties can come in two types, AudioParam and NodeProperty. While the Web 
Audio API doesn't make an official distinction between the two, how they are 
used differs.

AudioParams represent parameters that can be updated at either audio rate 
(a-rate) or control rate (k-rate). Other audio nodes can connect to an 
AudioParam and modulate its value in real time. Examples of AudioParams include 
frequency, gain, and delayTime.

**AudioParam:**

```json
{
    "type": "AudioParam",
    "label": "frequency",
    "value": 440
}
```

NodeProperties are any other parameter on an audio node. An example of a 
NodeProperty is an OscillatorNode's "type" parameter.

**NodeProperty:**

```json
{
   "type": "NodeProperty",
   "label": "type",
   "value": "square"
}
```

@docs encode, encodeGraph

-}

-- Imports ---------------------------------------------------------------------
import Json.Decode as Decode
import Json.Encode as Encode exposing (encode)
import WebAudio.Property as Property exposing (..)

-- Types -----------------------------------------------------------------------
{-| The core building block of any Web Audio signal graph. `Keyed` nodes are 
just like regular nodes but with an additonal `Key` property. This allows `Ref` 
nodes to reference them elsewhere in the graph!
-}
type Node
    = Node Type (List Property) (List Node)
    | Keyed Key Type (List Property) (List Node)
    | Ref Key


{-| A simple type alias representing the type of `Node`. This could be 
something like "OscillatorNode" or "RefNode".
-}
type alias Type =
    String


{-| A simple type alias representing unique key used to identify nodes. Use 
`Key`s like you would use the `id` attribute on a HTML element.
-}
type alias Key =
    String


{-| -}
type alias Graph =
    List Node


-- Node constructors -----------------------------------------------------------
{-| General way to construct Web Audio nodes. This is used to create all the 
helper functions below. You can use this function to define custom nodes by 
partially applying just the `type` parameter. This is handy if you're using a 
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


{-| A ref node is used to refer to a keyed node elsewhere in the graph. This is 
how we connect multiple "chains" of nodes together and represet a graph in a 
simple list.
-}
ref : Key -> Node
ref =
    Ref


{-| Use this function to apply a key to a node. In the case of already keyed 
nodes, or ref nodes, this will update the key to the new value.

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

-- Audio nodes -----------------------------------------------------------------
{-| An audio node that contains an audio buffer to play. A buffer is an array of
samples. These nodes are great for creating sample-heavy instruments like a drum
machine, or for looping music samples to play along to,

Common properties:

  - buffer
  - detune
  - loop
  - loopStart
  - loopEnd
  - playbackRate

See: <https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode>
-}
audioBufferSource : List Property -> List Node -> Node
audioBufferSource =
    Node "AudioBufferSourceNode"


{-| This is the "end" of an audio graph and usually represents your speakers or
other output device. If you want to hear a node, it needs to connect to the
audio destination.

See: <https://developer.mozilla.org/en-US/docs/Web/API/AudioDestinationNode>
-}
audioDestination : Node
audioDestination =
    Node "AudioDestinationNode" [] []


{-| A simple low-order filter like a lowpass or highpass filter. Connecting an
oscillator, biquadFilter, and gain node together gives you the most basic
synthesiser.

Filters are most often used to shape the tone of a sound. A lowpass filter, for
example, cuts off high frequencies and makes a sound darker or more dull.

Common properties:

  - frequency
  - detune
  - Q
  - type

See: <https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode>
-}
biquadFilter : List Property -> List Node -> Node
biquadFilter =
    Node "BiquadFilterNode"


{-| Merges multiple mono inputs into a single multi-channel output. Because of
the way elm-web-audio works, this node is largely useless as there is currently
no way to specify which channel a node should connect to.

See: <https://developer.mozilla.org/en-US/docs/Web/API/ChannelMergerNode>
-}
channelMerger : List Property -> List Node -> Node
channelMerger =
    Node "ChannelMergerNode"


{-| Splits a multi-channel input into a set of separate mono outputs. As with
channelMerger, because of the way elm-web-audio currently works there is no way
to address individual channels making this node largely useless.

See: <https://developer.mozilla.org/en-US/docs/Web/API/ChanneSplliterNode>
-}
channelSplitter : List Property -> List Node -> Node
channelSplitter =
    Node "ChannelSplitterNode"


{-| Represents a single value as an audio source. That is, if we create a
constantSource with an offset of 1, it will produce 44100 (or whatever the
sample rate is) 1s per second.

This may seem useless at first, but constantSource nodes can connect to many
properties at once and so can be used to manage multiple modulations at the 
same time. The offset property itself can be modulated by another audio node,
leading to complex modulations of multiple properties.

Common properties:

  - offset

See: <https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode>
-}
constantSource : List Property -> List Node -> Node
constantSource =
    Node "ConstantSource"


{-| Convolution is a process of combining two audio signals together to produce
a third. It's a fairly involved topic but just know it's not the same as simply
summing two audio signals together.

The most common use of a convolver is for reverb. An *impulse response* of a 
room or space is recorded and set as a convolver's buffer, then audio fed 
through the convolver node will sound like it was played in that space.

Common properties:

  - buffer
  - normalize | normalise

See: <https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode>
-}
convolver : List Property -> List Node -> Node
convolver =
    Node "ConvolverNode"


{-| An alias for `audioDestination`. DAC stands for digitial-to-analog converter
and may be more familiar terminology for developers coming from other audio
programming environments such as Max/MSP (plus it's shorter to type!).
-}
dac : Node
dac =
    audioDestination


{-| A delay node stores its input in a buffer and plays that back after a 
specified amount of time. A common trick is to connect the output of a delay 
into the input of itself (with a gain node inbetween), a process called 
feedback. Setting the gain node to be some value below 1 produces an echo that
fades out over time.

Common properties:

  - delayTime

See: <https://developer.mozilla.org/en-US/docs/Web/API/DelayNode>
-}
delay : List Property -> List Node -> Node
delay =
    Node "DelayNode"


{-| Compression is an effect that reduces the volume of the loudest parts of an
audio signal, reducing the *dynamic range*. This "flattens" an audio signal and
allows us to turn the volume up without the loudest parts causing distortion.

Common properties:

  - threshold
  - knee
  - ratio
  - reduction
  - attack
  - release

See: <https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode>
-}
dynamicsCompressor : List Property -> List Node -> Node
dynamicsCompressor =
    Node "DynamicsCompressorNode"


{-| A simple way to control the volume of any inputs connected to the gain node.
A gain value of 1 is essentially a no-op, the volume is unaffected. 

Because of the way the Web Audio API handles connections, a gain node with a 
value of 1 is a handy way of summing multiple audio signals together.

Common properties:

  - gain

See: <https://developer.mozilla.org/en-US/docs/Web/API/GainNode>
-}
gain : List Property -> List Node -> Node
gain =
    Node "GainNode"


{-| Creates a general infinite impulse response filter. This is getting a bit
deeper into DSP territory so if you don't know what these are you probably don't
need them.

**Note**: There are currently no properties for the `feedforward` and `feedback`
coefficients needed to construct these nodes exposed in `WebAudio.Property`.

See: <https://developer.mozilla.org/en-US/docs/Web/API/IIRFilterNode>
-}
iirFilter : List Property -> List Node -> Node
iirFilter =
    Node "IIRFilterNode"


{-| Produces a tone with a periodic waveform like a sine or square wave. This is
the basic building block of synthesis, you just need an oscillator connected to
the audioDestination to have a playable instrument!

Common properties:

  - frequency
  - detune
  - type

See: <https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode>
-}
oscillator : List Property -> List Node -> Node
oscillator =
    Node "OscillatorNode"


{-| An alias for `oscillator`.
-}
osc : List Property -> List Node -> Node
osc =
    oscillator


{-| The panner is used to position its input in some 3D space. It's a fairly
involved node with a whole bunch of properties. More often than not, though,
you'll be better served with the stereoPanner node (below) to position audio
left or right.

The MDN docs linked below are going to be the best resource if you're interested
in using this node.

Common properties:

  - coneInnerAngle
  - coneOuterAngle
  - coneOuterGain
  - distanceModel
  - maxDistance
  - orientationX
  - orientationY
  - orientationZ
  - panningModel
  - positionX
  - positionY
  - positionZ
  - refDistance
  - rolloffFactor

See: <https://developer.mozilla.org/en-US/docs/Web/API/PannerNode>
-}
panner : List Property -> List Node -> Node
panner =
    Node "PannerNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/StereoPannerNode>
Common properties:

  - pan

-}
stereoPanner : List Property -> List Node -> Node
stereoPanner =
    Node "StereoPannerNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode>
Common properties:

  - curve
  - oversample

-}
waveShaper : List Property -> List Node -> Node
waveShaper =
    Node "WaveShaperNode"


-- JSON encoding ---------------------------------------------------------------
{-| Converts a `Node` into a Json value. Use this to send a node through a port 
to javascipt, where it can be constructed into a Web Audio node!
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


{-| Encode a graph of nodes into a Json value. More than likely you'll use this 
more than `encode`
-}
encodeGraph : Graph -> Encode.Value
encodeGraph =
    Encode.list encode
