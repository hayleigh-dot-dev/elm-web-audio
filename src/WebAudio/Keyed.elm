module WebAudio.Keyed exposing
    ( Node
    , node
    , analyser, audioBufferSource, biquadFilter, channelMerger, channelSplitter, constantSource, convolver, delay, dynamicsCompressor, gain, iirFilter, oscillator, osc, stereoPanner, waveShaper
    )

{-|


# Types

@docs Node


# Basic constructor

@docs node


# Web Audio Nodes

@docs analyser, audioBufferSource, biquadFilter, channelMerger, channelSplitter, constantSource, convolver, delay, dynamicsCompressor, gain, iirFilter, oscillator, osc, stereoPanner, waveShaper

-}

import WebAudio exposing (..)
import WebAudio.Property as Property exposing (..)

{-| -}
type alias Node =
    WebAudio.Node


{-| A keyed node is useful when we want to create more than
just simple chains of nodes. If we want to connect two
oscillators to the same gain node, for example, we can
key the gain node and use a `ref` node (below) to reference
it:

    graph : List Node
    graph =
        [ keyedGain "myGain"
            [ Property.gain 0.5 ]
            [ dac ]
        , osc [ Property.freq 440 ]
            [ ref "myGain" ]
        , osc [ Property.freq 880 ]
            [ ref "myGain" ]
        ]

-}
node : Key -> WebAudio.Type -> List Property -> List Node -> Node
node =
    Keyed


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode>
-}
analyser : String -> List Property -> List Node -> Node
analyser k =
    node k "AnalyserNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode>
-}
audioBufferSource : String -> List Property -> List Node -> Node
audioBufferSource k =
    node k "AudioBufferSourceNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode>
-}
biquadFilter : String -> List Property -> List Node -> Node
biquadFilter k =
    node k "BiquadFilterNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ChannelMergerNode>
-}
channelMerger : String -> List Property -> List Node -> Node
channelMerger k =
    node k "ChannelMergerNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ChanneSplliterNode>
-}
channelSplitter : String -> List Property -> List Node -> Node
channelSplitter k =
    node k "ChannelSplitterNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode>
-}
constantSource : String -> List Property -> List Node -> Node
constantSource k =
    node k "ConstantSource"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode>
-}
convolver : String -> List Property -> List Node -> Node
convolver k =
    node k "ConvolverNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/DelayNode>
-}
delay : String -> List Property -> List Node -> Node
delay k =
    node k "DelayNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode>
-}
dynamicsCompressor : String -> List Property -> List Node -> Node
dynamicsCompressor k =
    node k "DynamicsCompressorNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/GainNode>
-}
gain : String -> List Property -> List Node -> Node
gain k =
    node k "GainNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/>
-}
iirFilter : String -> List Property -> List Node -> Node
iirFilter k =
    node k "IIRFilterNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode>
-}
oscillator : String -> List Property -> List Node -> Node
oscillator k =
    node k "OscillatorNode"


{-| An alias for `oscillator`.
-}
osc : String -> List Property -> List Node -> Node
osc k =
    oscillator k


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/StereoPannerNode>
-}
stereoPanner : String -> List Property -> List Node -> Node
stereoPanner k =
    node k "StereoPannerNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode>
-}
waveShaper : String -> List Property -> List Node -> Node
waveShaper k =
    node k "WaveShaperNode"
