class DFIR.FullscreenQuad
  constructor: ->
    @vertices = [
      -1.0, -1.0,
      1.0, -1.0,
      -1.0, 1.0,
      
      -1.0, 1.0,
      1.0, -1.0,
      1.0, 1.0
    ]
    
    @textureCoords = [
      0.0, 0.0,
      1.0, 0.0,
      0.0, 1.0,
      
      0.0, 1.0,
      1.0, 0.0,
      1.0, 1.0
    ]
    
    @vertexBuffer = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array(@vertices), gl.STATIC_DRAW
    
    @textureBuffer = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @textureCoords
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array(@textureCoords), gl.STATIC_DRAW
    
    gl.bindBuffer gl.ARRAY_BUFFER, null
