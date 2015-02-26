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
  constructor: ->
    
    
  createFrameBuffer: ->
    @ext = gl.getExtension 'WEBGL_draw_buffers'
    @frameBuffer = gl.createFramebuffer()
    gl.bindFramebuffer gl.FRAMEBUFFER, @frameBuffer
    
    # albedo
    @albedoTextureUnit = @createTexture()
    gl.framebufferTexture2D gl.FRAMEBUFFER, @ext.COLOR_ATTACHMENT0_WEBGL, gl.TEXTURE_2D, @albedoTextureUnit, 0
    
    # normals
    @normalsTextureUnit = @createTexture()
    gl.framebufferTexture2D gl.FRAMEBUFFER, @ext.COLOR_ATTACHMENT1_WEBGL, gl.TEXTURE_2D, @normalsTextureUnit, 0
    
    # depth
    @depthTextureUnit = @createTexture()
    gl.framebufferTexture2D gl.FRAMEBUFFER, @ext.COLOR_ATTACHMENT2_WEBGL, gl.TEXTURE_2D, @depthTextureUnit, 0
    
    
    
  createTexture: ->
    tex = gl.createTexture()
    gl.bindTexture gl.TEXTURE_2D, tex
    gl.bindTexture(gl.TEXTURE_2D, rttTexture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST)
    gl.generateMipmap(gl.TEXTURE_2D)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.viewportWidth, gl.viewportHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
    tex

  bind: ->
    

  release : ->
    
    
  getDepthTextureUnit: ->
    
  getAlbedoTextureUnit: ->
    
  getNormalsTextureUnit: ->
    
    