/* global AudioContext */

const defer = fn => setTimeout(fn, 0)

export class VirtualAudioGraph {
  // STATIC METHODS =========================================================

  //
  static prepare (graph = []) {
    // The first step in preparing the graph is to key each virtual node.
    // This is how we perform a diff between graphs and calculate what has
    // changed each update.
    const keyGraph = (graph, base = '') => {
      graph.forEach((node, i) => {
        // RefNodes always have a key, and they also
        // cannot have connections or properties
        // so we can just return early and move on.
        if (node.type === 'RefNode') return
        // Assign the node a key if it didn't already have one.
        // This is how we track changes to the graph in a slightly
        // more organised way
        if (!node.key) node.key = `${base}_${i}`
        // Recursively assign keys to this nodes connections.
        if (node.connections && node.connections.length > 0) {
          keyGraph(node.connections, node.key)
        }
      })

      return graph
    }

    // It is often most natural to represent the audio graph as a list
    // of trees, using RefNodes to "jump" between chains of node
    // connections. This isns't the easiest data structure to deal with
    // however, so the next step in preparation is the flatten the graph
    // into a single array.
    const flattenGraph = (graph, flatGraph = [], depth = 0) => {
      graph.forEach((node, i) => {
        // Don't push RefNodes to the flat graph.
        if (node.type !== 'RefNode') flatGraph.push(node)
        if (node.connections) flatGraph = flattenGraph(node.connections, flatGraph, depth + 1)
        // If we're deeper than the root of the graph, replace
        // this node with a reference to itself by key.
        if (depth > 0) graph[i] = { type: 'RefNode', key: node.key }
      })

      return flatGraph
    }

    // Finally, we sort the nodes in the graph by their key.
    const sortGraph = graph =>
      graph.sort((a, b) => a.key < b.key ? -1 : a.key > b.key ? 1 : 0)

    return sortGraph(flattenGraph(keyGraph(graph)))
  }

  //
  static diff (a, b, patches = { removed: [], created: [], updated: [] }) {
    for (let i = 0; i < Math.max(a.length, b.length); i++) {
      const nodeA = a[i]
      const nodeB = b[i]

      if (!nodeA) {
        // There was no previous node
        patches.created.push({ type: 'node', key: nodeB.key, data: nodeB })
        nodeB.connections.forEach(connection => {
          patches.created.push({ type: 'connection', key: nodeB.key, data: connection.key.split('.') })
        })
      } else if (!nodeB) {
        // The node has been removed
        patches.removed.push({ type: 'node', key: nodeA.key, data: nodeA })
      } else if (nodeA.key !== nodeB.key) {
        // The key of the node has changed
        patches.removed.push({ type: 'node', key: nodeA.key, data: nodeA })
        patches.created.push({ type: 'node', key: nodeB.key, data: nodeB })
        nodeB.connections.forEach(connection => {
          patches.created.push({ type: 'connection', key: nodeB.key, data: connection.key.split('.') })
        })
      } else if (nodeA.type !== nodeB.type) {
        // The key is the same, but the type of node has changed
        patches.updated.push({ type: 'node', key: nodeA.key, data: nodeB })
        nodeB.connections.forEach(connection => {
          patches.created.push({ type: 'connection', key: nodeB.key, data: connection.key.split('.') })
        })
      } else {
        // The node hasn't fundamentally changed, time to check if
        // its properties or connections has changed.
        // First, check properties...
        for (let j = 0; j < Math.max(nodeA.properties.length, nodeB.properties.length); j++) {
          const propA = nodeA.properties[j]
          const propB = nodeB.properties[j]

          //
          if (!propA) {
            patches.created.push({ type: 'property', key: nodeA.key, data: propB })
          } else if (!propB) {
            patches.removed.push({ type: 'property', key: nodeA.key, data: propA })
          } else if (propA.label !== propB.label) {
            patches.removed.push({ type: 'property', key: nodeA.key, data: propA })
            patches.created.push({ type: 'property', key: nodeA.key, data: propB })
          } else if (propA.value !== propB.value) {
            patches.updated.push({ type: 'property', key: nodeA.key, data: propB })
          }
        }

        // Then, check connections...
        for (let j = 0; j < Math.max(nodeA.connections.length, nodeB.connections.length); j++) {
          const connectionA = nodeA.connections[j]
          const connectionB = nodeB.connections[j]

          //
          if (!connectionA) {
            patches.created.push({ type: 'connection', key: nodeA.key, data: connectionB.key.split('.') })
          } else if (!connectionB) {
            patches.removed.push({ type: 'connection', key: nodeA.key, data: connectionA.key.split('.') })
          } else if (connectionA.key !== connectionB.key) {
            patches.removed.push({ type: 'connection', key: nodeA.key, data: connectionA.key.split('.') })
            patches.created.push({ type: 'connection', key: nodeA.key, data: connectionB.key.split('.') })
          }
        }
      }
    }

    return patches
  }

  // PUBLIC METHODS =========================================================

  //
  constructor (context = new AudioContext(), opts = {}) {
    // Borrowing a convetion from virtual dom libraries, the $ sign
    // is used to indicate "real" Web Audio bits, and the v- prefix
    // is used to indicate virtual elements.

    // $context is a reference to the `AudioContext` either passed in
    // or created on construction.
    this.$context = context
    // A reference to the real graph of audio nodes
    this.$nodes = {}
    // We keep track of the prebious graph so we can perform a diff
    // and work out what has changed between updates.
    this.vPrev = []

    // In most modern browsers an Audio Context starts in a
    // suspended state and requires some user interaction
    // before it can be resumed. Still, we can attempt to
    // resume the context ourselves in the developer passes
    // in the `autostart` option.
    if (opts.autostart) this.resume()
  }

  //
  update (vGraph = []) {
    // The accompanying library of virtual node functions
    // encourages a nested tree-like approach to describing
    // audio graphs. This isn't the easiest structure to deal
    // with, however, so a preparation step serves to wrestle
    // the graph into a more suitable shape.
    const vCurr = VirtualAudioGraph.prepare(vGraph)

    // A diff tracks everything that has been removed, created,
    // and updated between updates. We perform this step so we
    // only touch the audio nodes that need to be changed in some
    // way.
    const diff = VirtualAudioGraph.diff(this.vPrev, vCurr)

    // Remove nodes and properties from the graph.
    diff.removed.forEach(patch => {
      switch (patch.type) {
        case 'node':
          this._destroyNode(patch.key)
          break
        case 'property':
          this._removeProperty(patch.key, patch.data)
          break
        case 'connection':
          this._disconnect(patch.key, patch.data)
          break
      }
    })

    // Create new nodes and add new properties to
    // the graph.
    diff.created.forEach(patch => {
      switch (patch.type) {
        case 'node':
          this._createNode(patch.key, patch.data)
          break
        case 'property':
          this._setProperty(patch.key, patch.data)
          break
        case 'connection':
          defer(() => this._connect(patch.key, patch.data))
          break
      }
    })

    // Update existing nodes and properties in the
    // graph.
    diff.updated.forEach(patch => {
      switch (patch.type) {
        case 'node':
          this._destroyNode(patch.key)
          this._createNode(patch.key, patch.data)
          break
        case 'property':
          this._setProperty(patch.key, patch.data)
          break
        case 'connection':
          // Connections can't be updated
          break
      }
    })

    // Store the current graph for next time.
    this.vPrev = vCurr
  }

  // A thin wrapper of the `AudioContext.suspend()` method. This
  // bassically exists so developers don't have to reach in and
  // touch the "real" audio context directly.
  suspend () {
    this.$context.suspend()
  }

  // A thin wrapper of the `AudioContext.resume()` method. This
  // bassically exists so developers don't have to reach in and
  // touch the "real" audio context directly.
  resume () {
    this.$context.resume()
  }

  // PRIVATE METHODS ========================================================

  //
  _createNode (key, { type, properties }) {
    let $node = null

    //
    switch (type) {
      case 'AnalyserNode':
        $node = this.$context.createAnalyser()
        break
      case 'AudioBufferSourceNode':
        $node = this.$context.createBufferSource()
        break
      case 'AudioDestinationNode':
        $node = this.$context.destination
        break
      case 'BiquadFilterNode':
        $node = this.$context.createBiquadFilter()
        break
      case 'ChannelMergerNode':
        $node = this.$context.createChannelMerger()
        break
      case 'ChannelSplitterNode':
        $node = this.$context.createChannelSplitter()
        break
      case 'ConstantSourceNode':
        $node = this.$context.createConstantSource()
        break
      case 'ConvolverNode':
        $node = this.$context.createConvolver()
        break
      case 'DelayNode':
        const maxDelayTime = properties.find(({ label }) => label === 'maxDelayTime')
        $node = this.$context.createDelay((maxDelayTime && maxDelayTime.value) || 1)
        break
      case 'DynamicsCompressorNode':
        $node = this.$context.createDynamicsCompressor()
        break
      case 'GainNode':
        $node = this.$context.createGain()
        break
      case 'IIRFilterNode':
        const feedforward = properties.find(({ label }) => label === 'feedforward')
        const feedback = properties.find(({ label }) => label === 'feedback')
        $node = this.$context.createIIRFilter(
          (feedforward && feedforward.value) || [0],
          (feedback && feedback.value) || [1]
        )
        break
      case 'MediaElementAudioSourceNode':
        const mediaElement = properties.find(({ label }) => label === 'mediaElement')
        $node = this.$context.createMediaElementSource(
          document.querySelector(mediaElement.value)
        )
        break
      case 'MediaStreamAudioDestinationNode':
        $node = this.$context.createMediaStreamDestination()
        break
        // TODO: How should I handle creating / grabbing the media stream?
        // case 'MediaStreamAudioSourceNode':
        //   $node = this.$context.createMediaStreamSource(

        //   )
        //   break
      case 'OscillatorNode':
        $node = this.$context.createOscillator()
        break
      case 'PannerNode':
        $node = this.$context.createPanner()
        break
      case 'StereoPannerNode':
        $node = this.$context.createStereoPanner()
        break
      case 'WaveShaperNode':
        $node = this.$context.createWaveShaper()
        break
    }

    this.$nodes[key] = $node

    //
    properties.forEach(prop => this._setProperty(key, prop))

    // Certain nodes like oscillators must be started before
    // they will produce noise. We make the assumption that
    // these nodes should always start immediately after they
    // have been created, so if a `start` method exists we
    // call it.
    if ($node.start) $node.start()
  }

  //
  _destroyNode (key) {
    const $node = this.$nodes[key]

    if ($node.stop) $node.stop()
    $node.disconnect()

    delete this.$nodes[key]
  }

  //
  _setProperty (key, { type, label, value }) {
    const $node = this.$nodes[key]

    switch (type) {
      case 'NodeProperty':
        $node[label] = value
        break
      case 'AudioParam':
        $node[label].value = value
        break
      case 'ScheduledAudioParam':
        $node[label][value.method](value.target, value.time)
        break
    }
  }

  //
  _removeProperty (key, { type, label, value }) {
    const $node = this.$nodes[key]

    switch (type) {
      case 'NodeProperty':
        break
      case 'AudioParam':
        $node[label].value = $node[label].default
        break
      case 'ScheduledAudioParam':
        // TODO: work out how to cancel scheduled updates
        break
    }
  }

  //
  _connect (a, [b, param = null]) {
    if (b) this.$nodes[a].connect(param ? this.$nodes[b][param] : this.$nodes[b])
  }

  //
  _disconnect (a, [b, param = null]) {
    if (b) this.$nodes[a].disconnect(param ? this.$nodes[b][param] : this.$nodes[b])
  }
}
