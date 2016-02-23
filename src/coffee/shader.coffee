getShader = (id) ->
  shaderScript = document.getElementById id
  if !shaderScript
    return null
  str = ""
  k = shaderScript.firstChild
  while k
    if k.nodeType is 3
      str += k.textContent
    k = k.nextSibling
  shader = null
  if shaderScript.type is "x-shader/x-fragment"
    shader = gl.createShader gl.FRAGMENT_SHADER
  else if shaderScript.type is "x-shader/x-vertex"
    shader = gl.createShader gl.VERTEX_SHADER
  else
    return null

  gl.shaderSource shader, str
  gl.compileShader shader

  console.log id, gl.getShaderInfoLog( shader )

  if !gl.getShaderParameter(shader, gl.COMPILE_STATUS)
    console.log id, gl.getShaderInfoLog( shader )
    return null
  return shader



class DFIR.Uniform
  constructor: (@name, @shaderProgram) ->
    @location = gl.getUniformLocation @shaderProgram, @name

  setValue: (value) ->

class DFIR.UniformMat4 extends DFIR.Uniform
  setValue: (matrix) ->
    gl.uniformMatrix4fv @location, false, matrix

class DFIR.UniformFloat extends DFIR.Uniform
  setValue: (value) ->
    gl.uniform1f @location, value

class DFIR.UniformMat3 extends DFIR.Uniform
  setValue: (matrix) ->
    gl.uniformMatrix3fv @location, false, matrix

class DFIR.UniformVec3 extends DFIR.Uniform
  setValue: (vec) ->
    gl.uniform3fv @location, 3, vec


class DFIR.ShaderSource
  constructor: (@vertexSource, @fragmentSource) ->


class DFIR.ShaderLoader
  constructor: (@vertUrl, @fragUrl, @callback) ->

    @fragmentLoaded = false
    @vertexLoaded = false

    @result = new DFIR.ShaderSource()

    loadShaderAjax @vertUrl, @onVertexLoaded
    loadShaderAjax @fragUrl, @onFragmentLoaded

  checkLoaded: ->
    loaded = @fragmentLoaded and @vertexLoaded
    return @fragmentLoaded and @vertexLoaded

  buildShader: ->
    return buildShaderProgram( @result.vertexSource, @result.fragmentSource )

  onFragmentLoaded: (data) =>
    fragShader = gl.createShader gl.FRAGMENT_SHADER
    gl.shaderSource fragShader, data
    gl.compileShader fragShader

    if fragmentLog = gl.getShaderInfoLog fragShader
      console.log fragmentLog

    @result.fragmentSource = fragShader
    @fragmentLoaded = true
    if @checkLoaded()
      @callback @buildShader()


  onVertexLoaded: (data) =>
    vertShader = gl.createShader gl.VERTEX_SHADER
    gl.shaderSource vertShader, data
    gl.compileShader vertShader

    if log = gl.getShaderInfoLog( vertShader )
      console.log log

    @result.vertexSource = vertShader
    @vertexLoaded = true
    if @checkLoaded()
      @callback @buildShader()

  @load: (vertUrl, fragUrl, callback) ->
    new ShaderLoader vertUrl, fragUrl, callback


loadResource = (url, callback) ->



loadShaderAjax = (url, callback) ->
  request = new XMLHttpRequest()
  request.open 'GET', url

  request.onreadystatechange = () ->
    if request.readyState is 4
      callback request.responseText
  request.send()


buildShaderProgram = (vertexShader, fragmentShader) ->
  shaderProgram = gl.createProgram()
  gl.attachShader shaderProgram, vertexShader
  gl.attachShader shaderProgram, fragmentShader
  gl.linkProgram shaderProgram

  if log = gl.getProgramInfoLog shaderProgram
    console.log log

  shaderProgram

buildProgram = (vertexSourceId, fragmentSourceId) ->
  fragmentShader = getShader fragmentSourceId
  vertexShader = getShader vertexSourceId
  return buildProgramFromStrings vertexShader, fragmentShader

buildProgramFromStrings = (vertexSource, fragmentSource) ->
  shaderProgram = gl.createProgram()
  gl.attachShader shaderProgram, vertexSource
  gl.attachShader shaderProgram, fragmentSource
  gl.linkProgram shaderProgram

  console.log gl.getProgramInfoLog( shaderProgram )

  shaderProgram



shader_type_enums =
    0x8B50: 'FLOAT_VEC2',
    0x8B51: 'FLOAT_VEC3',
    0x8B52: 'FLOAT_VEC4',
    0x8B53: 'INT_VEC2',
    0x8B54: 'INT_VEC3',
    0x8B55: 'INT_VEC4',
    0x8B56: 'BOOL',
    0x8B57: 'BOOL_VEC2',
    0x8B58: 'BOOL_VEC3',
    0x8B59: 'BOOL_VEC4',
    0x8B5A: 'FLOAT_MAT2',
    0x8B5B: 'FLOAT_MAT3',
    0x8B5C: 'FLOAT_MAT4',
    0x8B5E: 'SAMPLER_2D',
    0x8B60: 'SAMPLER_CUBE',
    0x1400: 'BYTE',
    0x1401: 'UNSIGNED_BYTE',
    0x1402: 'SHORT',
    0x1403: 'UNSIGNED_SHORT',
    0x1404: 'INT',
    0x1405: 'UNSIGNED_INT',
    0x1406: 'FLOAT'

getShaderParams = (program) ->
  gl.useProgram program
  result =
    attributes : []
    uniforms : []
    attributeCount : 0
    uniformCount : 0

  activeUniforms = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS)
  activeAttributes = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES)

  for i in [0 ... activeUniforms]
    uniform = gl.getActiveUniform program, i
    uniform.typeName = shader_type_enums[ uniform.type ]
    result.uniforms.push uniform
    result.uniformCount += uniform.size

  for i in [0 ... activeAttributes]
    attribute = gl.getActiveAttrib program, i
    attribute.typeName = shader_type_enums[ attribute.type ]
    result.attributes.push attribute
    result.attributeCount += attribute.size
  result


loadTexture = (url, callback) ->
  tex = gl.createTexture()
  tex.image = new Image()
  tex.image.onload = ( ->
    gl.bindTexture gl.TEXTURE_2D, tex
    gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, true
    gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, tex.image
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT
    gl.generateMipmap gl.TEXTURE_2D
    gl.bindTexture gl.TEXTURE_2D, null
    callback tex )
  tex.image.src = url


class DFIR.TextureMapTypes
  @DIFFUSE = 0x01
  @NORMAL = 0x02
  @SPECULAR = 0x03
  @CUBE = 0x04
  @SPHERE = 0x05


class DFIR.Color
  constructor: (@r=1.0, @g=1.0, @b=1.0, @a=1.0) ->

  getRGB: ->
    vec3.fromValues @r, @g, @b

  getRGBA: ->
    vec4.fromValues @r, @g, @b, @a


class DFIR.Shader
  constructor: (@program) ->
    @params = getShaderParams @program
    @diffuseMapLoaded = @normalMapLoaded = false
    @buildUniforms()
    @buildAttributes()

  buildUniforms : ->
    @uniforms = {}
    for u in @params.uniforms
      @uniforms[u.name] = gl.getUniformLocation @program, u.name

  buildAttributes : ->
    @attributes = {}
    for a in @params.attributes
      @attributes[a.name] = gl.getAttribLocation @program, a.name

  use : ->
    gl.useProgram @program

  showInfo: ->
    console.log @program
    console.table @params.uniforms
    console.table @params.attributes

  setDiffuseMap: (url) ->
    loadTexture url, (texture) =>
      @diffuseMap = texture
      @diffuseMapLoaded = true

  setNormalMap: (url) ->
    loadTexture url, (texture) =>
      @normalMap = texture
      @normalMapLoaded = true

  getUniform: (name) ->
    return @uniforms[name]

  getAttribute: (name) ->
    return @attributes[name]

class DFIR.PBRShader extends DFIR.Shader
  constructor: (@program) ->
    super( @program )
    @metallic = 0.0
    @roughness = 0.0
    @diffuseColor = new DFIR.Color()

  use: ->
    gl.useProgram @program
    gl.uniform1f(@getUniform('metallic'), @metallic)
    gl.uniform1f(@getUniform('roughness'), @roughness)
    gl.uniform3fv(@getUniform('diffuseColor'), @diffuseColor.getRGB())
