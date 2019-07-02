# Elm-Web-Audio

> *An elm/html-like library for the Web Audio API*.

## About
This library aims to provide a simple way of creating Web Audio processing graphs 
in Elm. It was motivated by the desire to keep as much of my audio code as possible
inside Elm before resorting to ports.

To that end I present an elm/html-like library for constructing *virtual* audio
graphs that can be sent through a port to be constructed in javascript. This means
entire audio processing graphs can be described in a powerful, declarative fashion
just like the DOM is:

```
-- elm/html
div : List Attribute -> List (Html a) -> Html a

-- elm-web-audio
osc : List Property -> List Node -> Node
```

This means we can naturally represent chains of audio nodes, and easily visualise
their connections:

```
audio : Model -> Graph
audio model =
  [ oscillator [ frequency model.freq ]
    [ audioDestination ]
  ]
```

Notice how we're using our application's Model to set the frequency of the oscillator.
If we hook our application up right, we get all the benefits of The Elm Architecture
for our audio graph just as we do for our view!

Checkout the example to see how everything gets hooked up.