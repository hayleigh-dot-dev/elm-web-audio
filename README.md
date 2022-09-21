# elm-web-audio

> *An `elm/html`-like library for the Web Audio API*.

## Motivation

The Web Audio API as it exists in JavaScript is a bit awkward to work with. In a
world where declarative view layers are commonplace, we are still stuck with
procedural code to create and manipulate audio nodes.

This package takes a different approach, and provides a declarative API for
constructing singal processing graphs in Elm. In fact, the API will be familiar
to anyone who has used `elm/html` before!

```elm
-- elm/html
div : List Attribute -> List (Html a) -> Html a

-- hayleigh-dot-dev/elm-web-audio
osc : List Property -> List Node -> Node
```

This means we can naturally represent chains of audio nodes, and easily visualise
their connections:

```elm
import WebAudio exposing (oscillator, delay, audioDestination)
import WebAudio.Property exposing (frequency, delayTime )

audio : Model -> List WebAudio.Node
audio model =
    [ oscillator [ frequency model.freq ]
        [ audioDestination
        , delay
            [ delayTime model.delay ]
            [ audioDestination ]
        ]
    ]
```

Here it's easy to see that we have an `oscillator` node connected to two nodes:
a `delay` node, and the `audioDestination` node. If you're wondering how to
represent more complex connections between nodes such as feedback loops, connecting
to audio params, or a nodes with multiple inputs, then you can explore the rest
of the package docs.

Notice how we're using our application's Model to set the frequency of the oscillator.
If we hook our application up right, we get all the benefits of The Elm Architecture
for our audio graph just as we do for our view!

## Usage

```elm
port module Main exposing (main)

import Browser
import Json.Encode
import WebAudio
import WebAudio.Property

port : toWebAudio : Json.Encode.Value -> Cmd msg

main : Program Flags Model Msg
main =
    Browser.element
        { init = ...
        , update = 
            \msg model ->
                let 
                    ( mod, cmd ) = update msg model 
                in
                ( mod
                , Cmd.batch 
                    [ cmd
                    , audio mod 
                        |> Json.Encode.list WebAudio.encode
                        |> toWebAudio
                    ]
                ) 
        , view = ...
        , subscriptions = ...
        }


audio : Model -> List WebAudio.Node
audio model =
    [ WebAudio.oscillator 
        [ WebAudio.Property.frequency model.freq ]
        [ WebAudio.audioDestination
        , WebAudio.delay
            [ WebAudio.Property.delayTime model.delay ]
            [ WebAudio.audioDestination ]
        ]
    ]
```

There is a hacked together example of a "Virtual Audio Context" in this repository
as `elm-web-audio.js`. This is a basic implementation that manages the actual
Web Audio graph, diffing it against new graphs coming from your elm app, and
applying the appropriate patches.

It would be great if someothing a bit nicer and more robust was available: if
you're interested in helping out, please get in touch!

```js
import { Elm } from './Main.elm'
import VirtualAudioContext from './elm-web-audio.js'

const ctx = new AudioContext()
const virtualCtx = new VirtualAudioContext(ctx)

const app = Elm.Main.init({
    node: document.getElementById('root'),
    flags: {
        // ...
    }
})

app.ports.toWebAudio.subscribe((nodes) => {
    virtualCtx.update(nodes)
})
```
