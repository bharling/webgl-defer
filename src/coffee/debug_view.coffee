class DebugView
  constructor: (@gbuffer, num_views=6) ->
    @depthTex = @gbuffer.getDepthTextureUnit()
    @normalsTex = @guffer.getNormalsTexture()
    @albedoTex = @gbuffer.getAlbedoTextureUnit()
    @createMaterial()
    @createQuads num_views
    
  draw: (camera) ->
    @material.use()
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getDepthTextureUnit())
    
    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getNormalsTextureUnit())
    
    gl.activeTexture(gl.TEXTURE2);
    gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getAlbedoTextureUnit())
    
    gl.uniform1i(@material.getUniform('depthTexture'), 0)
    gl.uniform1i(@material.getUniform('normalsTexture'), 1)
    gl.uniform1i(@material.getUniform('albedoTexture'), 2)
    gl.uniformMatrix4fv(@material.getUniform('inverseProjectionMatrix'), false, camera.getInverseProjectionMatrix());
    
    #gl.uniform4f(quad.material.getUniform('projectionParams'), projectionParams[0], projectionParams[1], projectionParams[2], projectionParams[3] );
    for i in [0 .. @quads.length]
      @drawQuad i
    
    
  drawQuad:(index) ->
    @quads[i].bind()
    gl.uniform1i(@material.getUniform('DEBUG'), index)
    
    # need to pass in a 2d transformation matrix, each quad should have one
    # TODO: Store a transform matrix for each quad
    gl.drawArrays(gl.TRIANGLES, 0, @quads[i].vertexBuffer.numItems)
    @quads[i].release()
    
  createMaterial: ->
    @material = new DFIR.Shader ( "fs_quad_vert", "fs_quad_frag" )
    @debug_uniform_location = @material.getUniform('DEBUG')
    
  createQuads: (num) ->
    scale = 0.2
    @quads = []
    #for i in [0 .. num]
    
  createQuad: (x, y, w, h) ->
    
    
    
    
  
