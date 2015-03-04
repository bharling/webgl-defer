gbuffer_vert = """
  
  attribute vec3 aVertexNormal;
  attribute vec3 aVertexPosition;
  attribute vec2 aVertexTextureCoords;
  
  uniform mat4 uMVMatrix;
  uniform mat4 uPMatrix;
  
  varying vec2 vTexCoords;
  varying float depth;
  varying vNormal;
  
  void main (void) {
      vTexCoords = aVertexTextureCoords;
      gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);    
      depth = gl_Position.z;
      vec4 n = uMVMatrix * vec4(aVertexNormal, 1.0);
      vNormal = vec3(n.xyz);
  }
""";

gbuffer_frag = """
  #extension GL_EXT_draw_buffers : require
  precision mediump float;
  varying vec3 vNormal;
  varying vec2 vTexCoords;
  varying float depth;
  
  uniform float farClip;
  uniform float nearClip;
  
  vec4 pack (float depth) {
    const vec4 bitSh = vec4(
      256*256*256,
      256*256,
      256,
      1.0
    );
    
    const vec4 bitMask = vec4 (
      0.0,
      1.0 / 256.0,
      1.0 / 256.0,
      1.0 / 256.0
    );
    
    vec4 comp = fract(depth * bitSh);
    comp -= comp.xxyz * bitMask;
    return comp;
  }
  
  
  void main (void) {
    gl_FragData[0] = vec4(0.5,0.5,0.5,1.0);
    gl_FragData[1] = vec4(vNormal, 1.0);
    gl_FragData[2] = pack(1.0 - depth/farClip);
  }
""";

class DFIR.Gbuffer
  
  constructor: (@resolution=1.0) ->
    @width = gl.viewportWidth / @resolution
    @height = gl.viewportHeight / @resolution
    @createFrameBuffer()
    
    
  createFrameBuffer: ->
    @ext = gl.getExtension 'WEBGL_draw_buffers'
    
    
    
    @DepthEXT = gl.getExtension( "WEBKIT_WEBGL_depth_texture" ) or gl.getExtension( "WEBGL_depth_texture" )
    
    
    @frameBuffer = gl.createFramebuffer()
    gl.bindFramebuffer gl.FRAMEBUFFER, @frameBuffer
    
    # create Texture Units
    @albedoTextureUnit = @createTexture()
    @normalsTextureUnit = @createTexture()
    @depthTextureUnit = @createTexture()
    @depthComponent = @createDepthTexture()
    
    gl.framebufferTexture2D gl.FRAMEBUFFER, @ext.COLOR_ATTACHMENT0_WEBGL, gl.TEXTURE_2D, @albedoTextureUnit, 0
    gl.framebufferTexture2D gl.FRAMEBUFFER, @ext.COLOR_ATTACHMENT1_WEBGL, gl.TEXTURE_2D, @normalsTextureUnit, 0
    gl.framebufferTexture2D gl.FRAMEBUFFER, @ext.COLOR_ATTACHMENT2_WEBGL, gl.TEXTURE_2D, @depthTextureUnit, 0
    gl.framebufferTexture2D gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, @depthComponent, 0
    
    
    console.log( "GBuffer FrameBuffer status after initialization: " );
    console.log( gl.checkFramebufferStatus( gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE );
    
    
    # set draw targets
    @ext.drawBuffersWEBGL [
        @ext.COLOR_ATTACHMENT0_WEBGL,
        @ext.COLOR_ATTACHMENT1_WEBGL,
        @ext.COLOR_ATTACHMENT2_WEBGL
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


  createTexture: ->
    tex = gl.createTexture()
    gl.bindTexture gl.TEXTURE_2D, tex
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @width, @height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
    tex

  bind: ->
    gl.bindFramebuffer gl.FRAMEBUFFER, @frameBuffer


  release : ->
    gl.bindTexture gl.TEXTURE_2D, null
    gl.bindFramebuffer gl.FRAMEBUFFER, null
    
    
  getDepthTextureUnit: ->
    @depthTextureUnit
    
  getAlbedoTextureUnit: ->
    @albedoTextureUnit
    
  getNormalsTextureUnit: ->
    @normalsTextureUnit
    