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


class DFIR.DebugGridView
  constructor: (num_levels) ->
    @build_geometry num_levels
    
    
  build_geometry: (num_levels) ->
    x = -1.0
    y = -1.0
    
    
    ht = 2.0 / num_levels
    
    
    
    wd = 0.5
    
    @vertices = []
    @textureCoords = []
    @indices = []
    
    f = 0
    
    for current_level in [1 .. num_levels]
      
      console.log current_level
      
      verts = [
        x, y, current_level,
        x+ht, y, current_level,
        x+ht, y+ht, current_level,
        x, y+ht, current_level
      ]
      
      
      texcoords = [
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0
      ]
      
      indices = [
        f, f+1, f+2,
        f+2, f+3, f
      ]
      
      f += 4
      
      x = x + ht
      
      
      
      @vertices = @vertices.concat verts
      @textureCoords = @textureCoords.concat texcoords
      @indices = @indices.concat indices
      

      
    
    
    @vertexBuffer = new DFIR.Buffer new Float32Array(@vertices), 3, gl.STATIC_DRAW
    @textureBuffer = new DFIR.Buffer new Float32Array(@textureCoords), 2, gl.STATIC_DRAW
    @indexBuffer = new DFIR.Buffer( new Uint16Array( @indices ), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER )
    console.log @indices
    console.log @vertices

    
  bind: (material) ->
    
    #console.log material
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer.get()
    gl.enableVertexAttribArray material.getAttribute('aVertexPosition')
    gl.vertexAttribPointer material.getAttribute( 'aVertexPosition'), 3, gl.FLOAT, false, 0, 0
    
    gl.bindBuffer gl.ARRAY_BUFFER, @textureBuffer.get()
    gl.enableVertexAttribArray material.getAttribute('aVertexTextureCoords')
    gl.vertexAttribPointer material.getAttribute( 'aVertexTextureCoords'), 2, gl.FLOAT, false, 0, 0
    
  draw: ->
    gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @indexBuffer.get()
    gl.drawElements gl.TRIANGLES, @indexBuffer.numItems, gl.UNSIGNED_SHORT, 0
    
  release: ->
    gl.bindBuffer gl.ARRAY_BUFFER, null
    
  


class DFIR.FullscreenQuad extends DFIR.Object3D
  constructor: ->
    super()
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
    
    
    
