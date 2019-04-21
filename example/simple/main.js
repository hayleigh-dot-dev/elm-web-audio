import { Elm } from './Main.elm'

const context = new AudioContext()
const nodes = {}

// Chrome autplay policy demans some user interaction 
// takes place before the AudioContext can be resumed.
document.addEventListener('click', () => {
  if (context.state === "suspended") context.resume()
})

const App = Elm.Main.init({
  node: document.querySelector('#app')
})

App.ports.fromElm.subscribe(graph => simpleAudio(graph))

// A super simple function to turn our virtual
// audio graph into real Web Audio nodes. It assumes
// the nodes in the grpah never change, you probably
// want to implement something a bit more sophisticated
// in real world apps!
const simpleAudio = graph => {
  // Iterate once to assign keys and construct
  // the nodes.
  const createNodes = (graph, base = '') => graph.forEach((vNode, i) => {
    // Mutate the vNode in place, and se its key
    // if it doesn't have one.
    vNode.key = vNode.key || base + '#' + i
    // Because the nodes object starts empty, we can
    // just check if a node currently exists at the key.
    // If it doesn't, go ahead and create one.
    if (!nodes[vNode.key]) nodes[vNode.key] = createNode(vNode)

    // Update all the properties on the node. This does assume
    // that any AudioParams in particular do actually exist on
    // the node.
    vNode.properties.forEach(prop => {
      switch (prop.type) {
        case "AudioParam":
          nodes[vNode.key][prop.label].value = prop.value
          break
        case "NodeProperty":
          nodes[vNode.key][prop.label] = prop.value
          break
        }
    })

    // Recursion on each of the node's connections
    createNodes(vNode.connections, vNode.key)
  })

  // Iterate a second time to connect all the
  // nodes together.
  const connectNodes = graph => graph.forEach(vNode => {
    vNode.connections.forEach(connection => {
      nodes[vNode.key].connect(nodes[connection.key])
    })

    // Recursion on each of the node's connections
    connectNodes(vNode.connections)
  })

  createNodes(graph)
  connectNodes(graph)
}

const createNode = vNode => {
  let $node = null

  switch (vNode.type) {
    case 'AnalyserNode':
      $node = new AnalyserNode(context)
      break
    case 'AudioBufferSourceNode':
      $node = new AudioBufferSourceNode(context)
      break
    case 'AudioDestinationNode':
      $node = context.destination
      break
    case 'AudioScheduledSourceNode':
      $node = new AudioScheduledSourceNode(context)
      break
    case 'BiquadFilterNode':
      $node = new BiquadFilterNode(context)
      break
    case 'ChannelSplitterNode':
      $node = new ChannelSplitterNode(context)
      break
    case 'ConstantSourceNode':
      $node = new ConstantSourceNode(context)
      break
    case 'ConvolverNode':
      $node = new ConvolverNode(context)
      break
    case 'DelayNode':
      $node = new DelayNode(context)
      break
    case 'DynamicsCompressorNode':
      $node = new DynamicsCompressorNode(context)
      break
    case 'GainNode':
      $node = new GainNode(context)
      break
    case 'IIRFilterNode':
      $node = new IIRFilterNode(context)
      break
    case 'MediaElementAudioSourceNode':
      $node = new MediaElementAudioSourceNode(context)
      break
    case 'MediaStreamAudioDestinationNode':
      $node = new MediaStreamAudioDestinationNode(context)
      break
    case 'MediaStreamAudioSourceNode':
      $node = new MediaStreamAudioSourceNode(context)
      break
    case 'OscillatorNode':
      $node = new OscillatorNode(context)
      break
    case 'PannerNode':
      $node = new PannerNode(context)
      break
    case 'StereoPannerNode':
      $node = new StereoPannerNode(context)
      break
    case 'WaveShaperNode':
      $node = new WaveShaperNode(context)
      break
  }

  // Nodes that inherit from AudioScheduledSource
  // must be start()ed before they produce sound.
  if ($node.start) $node.start()

  return $node
}