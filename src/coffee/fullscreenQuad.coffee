fs_quad_vertex_shader = """
  attribute vec3 aVertexPosition;
  attribute vec2 aVertexTextureCoords;
  
  varying vec2 vTexCoords;
  
  void main( void ) {
    // passthru
    gl_Position = vec4(aVertexPosition, 1.0);
    
    vTexCoords = aVertexTextureCoords;
  }

"""

fs_quad_fragment_shader = """
  varying vec2 vTexCoords;
  
  void main (void) {
    gl_FragColor = vec4(vTexCoords, 1.0, 1.0);
  }

"""






class DFIR.FullscreenQuad
  constructor: ->
    @vertices = [
      -1.0, -1.0,
       1.0, -1.0,
      -1.0,  1.0,
      
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
    
    @vertexBuffer = new DFIR.Buffer new Float32Array(@vertices), 2, gl.STATIC_DRAW
    @textureBuffer = new DFIR.Buffer new Float32Array(@textureCoords), 2, gl.STATIC_DRAW
    
    
  setMaterial : (shader) ->
    @material = shader
    
  bind: ->
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer.get()
    gl.enableVertexAttribArray @material.getAttribute('aVertexPosition')
    gl.vertexAttribPointer @material.getAttribute( 'aVertexPosition'), 2, gl.FLOAT, false, 0, 0
    
    gl.bindBuffer gl.ARRAY_BUFFER, @textureBuffer.get()
    gl.enableVertexAttribArray @material.getAttribute('aVertexTextureCoords')
    gl.vertexAttribPointer @material.getAttribute( 'aVertexTextureCoords'), 2, gl.FLOAT, false, 0, 0
    
  release: ->
    gl.bindBuffer gl.ARRAY_BUFFER, null
    
    
    
