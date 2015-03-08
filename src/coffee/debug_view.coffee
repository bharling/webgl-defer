class DebugView
  constructor: (@gbuffer) ->
    @depthTex = @gbuffer.getDepthTextureUnit()
    @normalsTex = @guffer.getNormalsTexture()
    @albedoTex = @gbuffer.getAlbedoTextureUnit()
    
  createQuad: (px,py,pixWidth,pixHeight) ->
    
    
  getShader: (debug_level) ->
    
    
  
