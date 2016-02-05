class DFIR.Gbuffer
  
  constructor: (@resolution=1.0) ->
    @width = gl.viewportWidth / @resolution
    @height = gl.viewportHeight / @resolution
    @createFrameBuffer()
    
    
  createFrameBuffer: ->
    @mrt_ext = gl.getExtension 'WEBGL_draw_buffers'
    
    @half_ext = gl.getExtension("OES_texture_half_float")
    
    @depth_ext = gl.getExtension( "WEBKIT_WEBGL_depth_texture" ) or gl.getExtension( "WEBGL_depth_texture" )
    
    @frameBuffer = gl.createFramebuffer()
    gl.bindFramebuffer gl.FRAMEBUFFER, @frameBuffer
    
    # create Texture Units
    @albedoTextureUnit = @createTexture()
    @normalsTextureUnit = @createTexture(half_ext.HALF_FLOAT_OES)
    #@depthTextureUnit = @createTexture()
    @depthComponent = @createDepthTexture()
    
    gl.framebufferTexture2D gl.FRAMEBUFFER, @mrt_ext.COLOR_ATTACHMENT0_WEBGL, gl.TEXTURE_2D, @albedoTextureUnit, 0
    gl.framebufferTexture2D gl.FRAMEBUFFER, @mrt_ext.COLOR_ATTACHMENT1_WEBGL, gl.TEXTURE_2D, @normalsTextureUnit, 0
    #gl.framebufferTexture2D gl.FRAMEBUFFER, @mrt_ext.COLOR_ATTACHMENT2_WEBGL, gl.TEXTURE_2D, @depthTextureUnit, 0
    gl.framebufferTexture2D gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, @depthComponent, 0
    
    
    console.log( "GBuffer FrameBuffer status after initialization: " );
    console.log( gl.checkFramebufferStatus( gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE );
    
    
    # set draw targets
    @mrt_ext.drawBuffersWEBGL [
        @mrt_ext.COLOR_ATTACHMENT0_WEBGL,
        @mrt_ext.COLOR_ATTACHMENT1_WEBGL,
        #@mrt_ext.COLOR_ATTACHMENT2_WEBGL
      ]
      
    @release()
    
    # depth renderbuffer TODO: do we need this?
    #@renderBuffer = gl.createRenderbuffer()
    #gl.bindRenderbuffer gl.RENDERBUFFER, @renderBuffer
    #gl.renderbufferStorage gl.RENDERBUFFER, gl.DEPTH_STENCIL, @width, @height
    
    #gl.framebufferRenderbuffer gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, @renderbuffer 
    
    
  createDepthTexture: ->
    tex = gl.createTexture()
    gl.bindTexture gl.TEXTURE_2D, tex
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT, @width, @height, 0, gl.DEPTH_COMPONENT, gl.UNSIGNED_SHORT, null)
    tex


  createTexture: (format) ->
    format = @half_ext.HALF_FLOAT_OES
    tex = gl.createTexture()
    gl.bindTexture gl.TEXTURE_2D, tex
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @width, @height, 0, gl.RGBA, format, null)
    tex

  bind: ->
    gl.bindFramebuffer gl.FRAMEBUFFER, @frameBuffer
    #gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT


  release : ->
    #gl.bindTexture gl.TEXTURE_2D, null
    gl.bindFramebuffer gl.FRAMEBUFFER, null
    
    
  getDepthTextureUnit: ->
    @depthComponent #@depthTextureUnit
    
  getAlbedoTextureUnit: ->
    @albedoTextureUnit
    
  getNormalsTextureUnit: ->
    @normalsTextureUnit
    