class DFIR.Buffer
  constructor: (data, @itemSize, @mode, @type) ->
    # create an empty VBO
    
    @type ?= gl.ARRAY_BUFFER
    
    
    @buffer = gl.createBuffer()
    
    # bind it to use
    gl.bindBuffer @type, @buffer
    
    # upload the data ( expecting data to be a Float32Array, and mode to be gl.STATIC_DRAW etc. )
    gl.bufferData @type, data, @mode
    
    # cache number of items in this array
    @numItems = data.length / @itemSize
    
  bind: ->
    gl.bindBuffer @type, @buffer
    
  get: ->
    return @buffer
    
  release: ->
    gl.bindBuffer @type, null
    
