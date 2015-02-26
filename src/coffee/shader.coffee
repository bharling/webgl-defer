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
  
  if !gl.getShaderParameter(shader, gl.COMPILE_STATUS)
    alert gl.getShaderInfoLog( shader )
    return null
    
  return shader
  
  
buildProgram = (vertexSourceId, fragmentSourceId) ->
  fragmentShader = getShader fragmentSourceId
  vertexShader = getShader vertexSourceId
  
  shaderProgram = gl.createProgram()
  gl.attachShader shaderProgram, vertexShader
  gl.attachShader shaderProgram, fragmentShader
  gl.linkProgram shaderProgram
  
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
  

class DFIR.Shader
  constructor: (vertSourceId, fragSourceId) ->
    @program = buildProgram vertSourceId, fragSourceId
    @params = getShaderParams @program
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
    console.table @params.uniforms
    console.table @params.attributes
    
  getUniform: (name) ->
    return @uniforms[name]
    
  getAttribute: (name) ->
    return @attributes[name]
    
    
    
  
  

