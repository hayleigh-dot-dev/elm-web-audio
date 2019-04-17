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


{-| 
-}
analyser : String -> List Property -> List Node -> Node
analyser k =
    node k "AnalyserNode"


{-| 
-}
audioBufferSource : String -> List Property -> List Node -> Node
audioBufferSource k =
    node k "AudioBufferSourceNode"


{-| 
-}
biquadFilter : String -> List Property -> List Node -> Node
biquadFilter k =
    node k "BiquadFilterNode"


{-| 
-}
channelMerger : String -> List Property -> List Node -> Node
channelMerger k =
    node k "ChannelMergerNode"


{-| 
-}
channelSplitter : String -> List Property -> List Node -> Node
channelSplitter k =
    node k "ChannelSplitterNode"


{-| 
-}
constantSource : String -> List Property -> List Node -> Node
constantSource k =
    node k "ConstantSource"


{-| 
-}
convolver : String -> List Property -> List Node -> Node
convolver k =
    node k "ConvolverNode"


{-| 
-}
delay : String -> List Property -> List Node -> Node
delay k =
    node k "DelayNode"


{-| 
-}
dynamicsCompressor : String -> List Property -> List Node -> Node
dynamicsCompressor k =
    node k "DynamicsCompressorNode"


{-| 
-}
gain : String -> List Property -> List Node -> Node
gain k =
    node k "GainNode"


{-| 
-}
iirFilter : String -> List Property -> List Node -> Node
iirFilter k =
    node k "IIRFilterNode"


{-| 
-}
oscillator : String -> List Property -> List Node -> Node
oscillator k =
    node k "OscillatorNode"


{-| 
-}
osc : String -> List Property -> List Node -> Node
osc k =
    oscillator k


{-| 
-}
stereoPanner : String -> List Property -> List Node -> Node
stereoPanner k =
    node k "StereoPannerNode"


{-| 
-}
waveShaper : String -> List Property -> List Node -> Node
waveShaper k =
    node k "WaveShaperNode"
