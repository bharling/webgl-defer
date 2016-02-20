###
 * @fileoverview DFIR Engine - Deferred WebGL render engine
 * @author Ben Harling
 * @version 0.7
 *

Copyright (c) 2016, Ben Harling

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

###

exports = if typeof exports isnt 'undefined' then exports else window


DFIR = {}
DFIR.currentId = 0

DFIR.nextId = () ->
	return DFIR.currentId++


exports.DFIR = DFIR




# add some missing mat3 stuff

mat3.makeTranslation = (tx, ty) ->
  tm = mat3.create()
  mat3.identity tm
  tm[6] = tx
  tm[7] = ty
  tm

mat3.makeRotation = (radians) ->
  c = Math.cos(radians)
  s = Math.sin(radians)

  rm = mat3.create()
  rm.identity()
  rm[0] = c
  rm[1] = -s
  rm[2] = 0
  rm[3] = s
  rm[4] = c
  rm[5] = 0
  rm[6] = 0
  rm[7] = 0
  rm[8] = 1
  rm

mat3.makeProjection = (w, h) ->
  pm = mat3.create()
  mat3.identity pm
  pm[0] = 2.0 / w
  pm[1] = 0
  pm[2] = 0
  pm[3] = 0
  pm[4] = -2.0 / h
  pm[5] = 0
  pm[6] = -1
  pm[7] = 1
  pm[8] = 1
  pm

mat3.makeScale = (sx, sy) ->
  sm = mat3.create()
  mat3.identity sm
  sm[0] = sx
  sm[4] = sy
  sm

mat3.multiply = (a,b) ->
  # multiply a by b
  a00 = a[0*3+0]
  a01 = a[0*3+1]
  a02 = a[0*3+2]
  a10 = a[1*3+0]
  a11 = a[1*3+1]
  a12 = a[1*3+2]
  a20 = a[2*3+0]
  a21 = a[2*3+1]
  a22 = a[2*3+2]
  b00 = b[0*3+0]
  b01 = b[0*3+1]
  b02 = b[0*3+2]
  b10 = b[1*3+0]
  b11 = b[1*3+1]
  b12 = b[1*3+2]
  b20 = b[2*3+0]
  b21 = b[2*3+1]
  b22 = b[2*3+2]

  ret = mat3.create()
  ret[0] = a00 * b00 + a01 * b10 + a02 * b20
  ret[1] = a00 * b01 + a01 * b11 + a02 * b21
  ret[2] = a00 * b02 + a01 * b12 + a02 * b22
  ret[3] = a10 * b00 + a11 * b10 + a12 * b20
  ret[4] = a10 * b01 + a11 * b11 + a12 * b21
  ret[5] = a10 * b02 + a11 * b12 + a12 * b22
  ret[6] = a20 * b00 + a21 * b10 + a22 * b20
  ret[7] = a20 * b01 + a21 * b11 + a22 * b21
  ret[8] = a20 * b02 + a21 * b12 + a22 * b22
  ret





# some simple stuff that I should replace later

pixelsToClip = ( pos ) ->
  px = pos[0] / gl.viewportWidth
  py = pos[1] / gl.viewportHeight
  px = px * 2.0
  py = py * 2.0
  px -= 1.0
  py -= 1.0
  py *= -1.0
  return [px,py]

class DFIR.Buffer
  constructor: (data, @itemSize, mode, type) ->
    # create an empty VBO
    
    type ?= gl.ARRAY_BUFFER
    
    
    @buffer = gl.createBuffer()
    
    # bind it to use
    gl.bindBuffer type, @buffer
    
    # upload the data ( expecting data to be a Float32Array, and mode to be gl.STATIC_DRAW etc. )
    gl.bufferData type, data, mode
    
    # cache number of items in this array
    @numItems = data.length / @itemSize
    
  bind: ->
    gl.bindBuffer @buffer
    
  get: ->
    return @buffer
    
  release: ->
    gl.bindBuffer null
    

class DFIR.Object2D




class DFIR.Object3D
  constructor: ->
    @position = vec3.create()
    @scale = vec3.fromValues 1.0, 1.0, 1.0
    @rotation = quat.create()
    @transform = mat4.create()
    @transformDirty = true
    @normalMatrix = mat3.create()
    @children = []
    @visible = true

  getWorldTransform: () ->
    if @transformDirty is true
      @updateWorldTransform()
    @transform

  draw: (camera, worldMatrix) ->
    if !@material or !@loaded
      return
    @material.use()
    @update()
    worldMatrix ?= @transform
    temp = mat4.create()

    mat4.multiply temp, camera.getViewMatrix(), worldMatrix

    
    worldViewProjectionMatrix = mat4.clone camera.getProjectionMatrix()
    mat4.multiply(worldViewProjectionMatrix, worldViewProjectionMatrix, camera.getViewMatrix())
    mat4.multiply(worldViewProjectionMatrix, worldViewProjectionMatrix, worldMatrix)
    mat3.normalFromMat4 @normalMatrix, worldMatrix
    @setMatrixUniforms(worldViewProjectionMatrix, @normalMatrix)
    @bindTextures()
    gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @vertexIndexBuffer.get()
    gl.drawElements gl.TRIANGLES, @vertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0


  bindTextures: () ->
    gl.activeTexture gl.TEXTURE0
    gl.bindTexture gl.TEXTURE_2D, @material.diffuseMap 
    gl.uniform1i @material.getUniform('diffuseTex'), 0 
    gl.activeTexture gl.TEXTURE1 
    gl.bindTexture gl.TEXTURE_2D, @material.normalMap 
    gl.uniform1i @material.getUniform('normalTex'), 1

  setMatrixUniforms: (wvpMatrix, normalMatrix) ->
    if !@material
      return null
    gl.uniformMatrix4fv @material.getUniform( 'uWorldViewProjectionMatrix' ), false, wvpMatrix
    gl.uniformMatrix3fv @material.getUniform( 'uNormalMatrix'), false, normalMatrix
    @setFloatUniform 'farClip', camera.far

  updateWorldTransform: (parentTransform = null) ->
    mat4.identity @transform
    mat4.translate @transform, @transform, @position
    mat4.scale @transform, @transform, @scale
    @transformDirty = false
    return

  setPosition: (pos) ->
    vec3.copy @position, pos
    @transformDirty = true

  setScale: (s) ->
    vec3.copy @scale, s
    @transformDirty = true

  translate: (vec) ->
    vec3.translate @position, vec
    @transformDirty = true

  rotateX: (rad) ->
    quat.rotateX @rotation, @rotation, rad
    @transformDirty = true

  rotateY: (rad) ->
    quat.rotateY @rotation, @rotation, rad
    @transformDirty = true

  rotateZ: (rad) ->
    quat.rotateZ @rotation, @rotation, rad
    @transformDirty = true

  visit: (func) ->
    if !@visible
      return
    func(@)
    for c in @children
      c.visit(func)

  update: ->
    if @transformDirty
      mat4.fromRotationTranslationScale @transform, @rotation, @position, @scale
      @transformDirty = false

  addChild: (childObject) ->
    @children.push childObject

  removeChild: (childObject) ->
    @children.remove childObject




class DFIR.Scene extends DFIR.Object3D

class DFIR.Mesh extends DFIR.Object3D
  constructor: (@geometry, @shader) ->
    super()
    @geometry ?= new DFIR.Geometry()
    @shader ?= new DFIR.BasicShader()

# taken from threejs
mergeVertices = (vertices, faces) ->
  verticesMap = {}
  unique = []
  changes = []
  precisionPoints = 4
  precision = Math.pow(10, precisionPoints)

  for i in [0 ... vertices.length] by 1
    v = vertices[i]
    key = "#{Math.round(v[0] * precision)}_#{Math.round(v[1] * precision)}_#{Math.round(v[2]*precision)}"
    if verticesMap[key]?
      changes[i] = changes[verticesMap[key]]
    else
      verticesMap[key] = i
      unique.push vertices[i]
      changes[i] = unique.length - 1


class DFIR.Face
  constructor: (@a, @b, @c) ->



class DFIR.Geometry



  constructor: ->
    @indices = []
    @faces = []
    @vertices = []
    @normals = []
    @texCoords = [[]]
    @vertexBuffer = null
    @texCoordBuffers = []
    @indexBuffer = null
    @normalBuffer = null


  #createVertexBuffer: (data, itemSize, mode) ->
#    mode ?= gl.STATIC_DRAW
#    itemSize ?= 3
#    @vertexBuffers.push new DFIR.Buffer( data, itemSize, mode )
##
#  createTextureCoordinateBuffer: (data, itemSize, mode) ->
#    mode ?= gl.STATIC_DRAW
#    itemSize ?= 2
#    @textureCoodBuffers.push new DFIR.Buffer( data, itemSize, mode )
#
#  createIndexBuffer: (data, itemSize, mode) ->
#    mode ?= gl.STATIC_DRAW
#    itemSize ?= 1
#    @indexBuffers.push new DFIR.Buffer (data, itemSize, mode )


DFIR.Geometry.meshCache = {}

class DFIR.Plane extends DFIR.Geometry
  constructor: (size, detail=1) ->
    hs = size / 2
    @vertices = [
      -hs, 0, 0,
      hs, 0, 0,
      hs, 0, hs,
      -hs, 0, hs
    ]

    @indexes = [
      
    ]

class DFIR.CubeGeometry extends DFIR.Geometry
  constructor: (size, detail=1) ->
    super()


class DFIR.SphereGeometry extends DFIR.Geometry
  constructor: (rings) ->
    super()

loadJSON = (url, callback) ->
  key = md5(url)
  console.log key
  if DFIR.Geometry.meshCache[key]?
    console.log 'Not loading #{url}'
    callback DFIR.Geometry.meshCache[key]
    return

  request = new XMLHttpRequest()
  request.open 'GET', url

  request.onreadystatechange = () ->
    if request.readyState is 4
      result = JSON.parse( request.responseText )
      DFIR.Geometry.meshCache[key] = result
      callback JSON.parse( request.responseText )
  request.send()



class DFIR.JSONGeometry extends DFIR.Object3D
  constructor: (url) ->
    super()
    loadJSON url, @onDataLoaded
    @material = null
    @loaded = false


  setMaterial : (shader) ->
    @material = shader



  bind : ->
    if !@material or !@loaded or !@material.diffuseMapLoaded or !@material.normalMapLoaded
      return false

    @material.use()

    positionAttrib = @material.getAttribute( 'aVertexPosition')
    texCoordsAttrib = @material.getAttribute( 'aVertexTextureCoords')
    normalsAttrib = @material.getAttribute( 'aVertexNormal' )


    gl.enableVertexAttribArray positionAttrib
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexPositionBuffer.get()
    gl.vertexAttribPointer positionAttrib, @vertexPositionBuffer.itemSize, gl.FLOAT, false, 12, 0

    gl.enableVertexAttribArray texCoordsAttrib
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexTextureCoordBuffer.get()
    gl.vertexAttribPointer texCoordsAttrib, @vertexTextureCoordBuffer.itemSize, gl.FLOAT, false, 8, 0

    gl.enableVertexAttribArray normalsAttrib
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexNormalBuffer.get()
    gl.vertexAttribPointer normalsAttrib, @vertexNormalBuffer.itemSize, gl.FLOAT, false, 12, 0
    return true

  release: ->
    gl.bindBuffer gl.ARRAY_BUFFER, null

  #setMatrixUniforms: (mvMatrix, pMatrix) ->
  #  if !@material
  #    return null
  #
  #  gl.uniformMatrix4fv @material.getUniform( 'uMVMatrix' ), false, mvMatrix
  #  gl.uniformMatrix4fv @material.getUniform( 'uPMatrix'), false, pMatrix

  setFloatUniform: (name, val) ->
    gl.uniform1f @material.getUniform(name), val

  setVec4Uniform: (name, x, y, z, w) ->
    gl.uniform4f @material.getUniform(name), x, y, z, w


  #draw : ->
  #  if !@material or !@loaded
  #    return
  #
  #  gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @vertexIndexBuffer.get()
  #  gl.drawElements gl.TRIANGLES, @vertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0

  onDataLoaded: (data) =>

    if data.vertexPositions?
      @vertexPositionBuffer = new DFIR.Buffer( new Float32Array( data.vertexPositions ), 3, gl.STATIC_DRAW )
      @vertexTextureCoordBuffer = new DFIR.Buffer( new Float32Array( data.vertexTextureCoords ), 2, gl.STATIC_DRAW )
      @vertexNormalBuffer = new DFIR.Buffer( new Float32Array( data.vertexNormals ), 3, gl.STATIC_DRAW )
      @vertexIndexBuffer = new DFIR.Buffer( new Uint16Array( data.indices ), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER )
      @loaded = true
    else if data.faces?
      @parseThreeJSModel data
      
      #@vertexIndexBuffer = new DFIR.Buffer( new Float32Array( data.faces ), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER )
      #@loaded = true

  parseThreeJSModel: (data) =>

    isBitSet = (value, position) ->
      return value & ( 1 << position )

    vertices = data.vertices
    uvs = data.uvs
    indices = []
    normals = data.normals

    vertexNormals = []
    vertexUvs = []
    vertexPositions = []

    @vertexPositionBuffer = new DFIR.Buffer( new Float32Array( data.vertices ), 3, gl.STATIC_DRAW )
    @vertexTextureCoordBuffer = new DFIR.Buffer( new Float32Array( data.uvs[0] ), 2, gl.STATIC_DRAW )

    numUvLayers = data.uvs.length
    faces = data.faces

    zLength = faces.length
    offset = 0

    while offset < zLength
      type = faces[offset++]
      isQuad              = isBitSet( type, 0 )
      hasMaterial         = isBitSet( type, 1 )
      hasFaceVertexUv     = isBitSet( type, 3 )
      hasFaceNormal       = isBitSet( type, 4 )
      hasFaceVertexNormal = isBitSet( type, 5 )
      hasFaceColor       = isBitSet( type, 6 )
      hasFaceVertexColor  = isBitSet( type, 7 )

      #console.log type

      if isQuad
        indices.push faces[ offset ]
        indices.push faces[ offset + 1 ]
        indices.push faces[ offset + 3 ]
        indices.push faces[ offset + 1 ]
        indices.push faces[ offset + 2 ]
        indices.push faces[ offset + 3 ]
        offset += 4

        if hasMaterial
          offset++

        if hasFaceVertexUv
          for i in [0 ... numUvLayers] by 1
            uvLayer = data.uvs[i]
            for j in [0 ... 4] by 1
              uvIndex = faces[offset++]
              u = uvLayer[ uvIndex * 2 ]
              v = uvLayer[ uvIndex * 2 + 1 ]

              if j isnt 2 
                vertexUvs.push u
                vertexUvs.push v
              if j isnt 0
                vertexUvs.push u
                vertexUvs.push v

        if hasFaceNormal
          offset++

        if hasFaceVertexNormal
          for i in [0 ... 4] by 1
              normalIndex = faces[ offset++ ] * 3
              normal = [ normalIndex++, normalIndex++, normalIndex ] 
              if i isnt 2
                vertexNormals.push normals[normal[0]]
                vertexNormals.push normals[normal[1]]
                vertexNormals.push normals[normal[2]]
              if i isnt 0
                vertexNormals.push normals[normal[0]]
                vertexNormals.push normals[normal[1]]
                vertexNormals.push normals[normal[2]]

        if hasFaceColor
          offset++

        if hasFaceVertexColor
          offset += 4
      else
        indices.push faces[offset++]
        indices.push faces[offset++]
        indices.push faces[offset++]

        if hasMaterial
          offset++
        if hasFaceVertexUv
          for i in [0 ... numUvLayers]
            uvLayer = data.uvs[i]
            for j in [0 ... 3]
              uvIndex = faces[offset++]
              u = uvLayer[ uvIndex * 2 ]
              v = uvLayer[ uvIndex * 2 + 1 ]
              if j isnt 2 
                vertexUvs.push u
                vertexUvs.push v
              if j isnt 0
                vertexUvs.push u
                vertexUvs.push v

        if hasFaceNormal
          console.log "hasFaceNormal"
          offset++

        if hasFaceVertexNormal
          for i in [0 ... 3] by 1
            normalIndex = faces[ offset++ ]
            vertexNormals.push normals[normalIndex++]
            vertexNormals.push normals[normalIndex++]
            vertexNormals.push normals[normalIndex]

            #vertexNormals.push 0.0
            #vertexNormals.push 1.0
            #vertexNormals.push 0.0
            

        if hasFaceColor
          offset++

        if hasFaceVertexColor
          offset +=3

    @vertexNormalBuffer = new DFIR.Buffer( new Float32Array( vertexNormals ), 3, gl.STATIC_DRAW )
    @vertexIndexBuffer = new DFIR.Buffer( new Uint16Array( indices ), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER )
    @loaded=true


      
  normalizeNormals: (normals) ->
    for i in [0 ... normals.length] by 3

      x = normals[ i ];
      y = normals[ i + 1 ]
      z = normals[ i + 2 ]

      n = 1.0 / Math.sqrt( x * x + y * y + z * z )

      normals[ i ] *= n
      normals[ i + 1 ] *= n
      normals[ i + 2 ] *= n
    return normals


  @load: (url) ->
    new DFIR.JSONGeometry url



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
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST
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

loadJSON = (url, callback) ->
  key = md5(url)
  console.log key
  if DFIR.Geometry.meshCache[key]?
    console.log 'Not loading #{url}'
    callback DFIR.Geometry.meshCache[key]
    return

  request = new XMLHttpRequest()
  request.open 'GET', url

  request.onreadystatechange = () ->
    if request.readyState is 4
      result = JSON.parse( request.responseText )
      DFIR.Geometry.meshCache[key] = result
      callback JSON.parse( request.responseText )
  request.send()


class DFIR.Resource

	constructor: ( @url=null ) ->
		@id = DFIR.nextId()

	load: () ->

	unload: () ->

	bind: () ->




class DFIR.ModelResource extends DFIR.Resource

	constructor: (@url ) ->
		super()
		loadJSON @url, @onDataLoaded

	setMaterial : (shader) ->
    	@material = shader

	onDataLoaded: (data) =>
	    @vertexPositionBuffer = new DFIR.Buffer( new Float32Array( data.vertexPositions ), 3, gl.STATIC_DRAW )
	    @vertexTextureCoordBuffer = new DFIR.Buffer( new Float32Array( data.vertexTextureCoords ), 2, gl.STATIC_DRAW )
	    @vertexNormalBuffer = new DFIR.Buffer( new Float32Array( data.vertexNormals ), 3, gl.STATIC_DRAW )
	    @vertexIndexBuffer = new DFIR.Buffer( new Uint16Array( data.indices ), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER )
	    @loaded = true


	ready: () ->
		return @ready or @ready = (@loaded && @material && @material.ready)?

	bind: () ->
		if !@ready()
			return false

		@material.use()

		positionAttrib = @material.getAttribute( 'aVertexPosition')
		texCoordsAttrib = @material.getAttribute( 'aVertexTextureCoords')
		normalsAttrib = @material.getAttribute( 'aVertexNormal' )


		gl.enableVertexAttribArray positionAttrib
		gl.bindBuffer gl.ARRAY_BUFFER, @vertexPositionBuffer.get()
		gl.vertexAttribPointer positionAttrib, @vertexPositionBuffer.itemSize, gl.FLOAT, false, 12, 0

		gl.enableVertexAttribArray texCoordsAttrib
		gl.bindBuffer gl.ARRAY_BUFFER, @vertexTextureCoordBuffer.get()
		gl.vertexAttribPointer texCoordsAttrib, @vertexTextureCoordBuffer.itemSize, gl.FLOAT, false, 8, 0

		gl.enableVertexAttribArray normalsAttrib
		gl.bindBuffer gl.ARRAY_BUFFER, @vertexNormalBuffer.get()
		gl.vertexAttribPointer normalsAttrib, @vertexNormalBuffer.itemSize, gl.FLOAT, false, 12, 0
		return true

  release: ->
    	gl.bindBuffer gl.ARRAY_BUFFER, null




# from https://github.com/pyalot/webgl-geoclipmapping/blob/master/src/camera/module.coffee

class InertialValue
  constructor: (@value, damping, @dt) ->
    @damping = Math.pow( damping, @dt )
    @last = @value
    @display = @value
    @velocity = 0

  accelerate: (acceleration) ->
    @velocity += acceleration * @dt

  integrate: ->
    @velocity *= @damping
    @last = @value
    @value += @velocity * @dt

  interpolate: (f) ->
    @display = @last*f + (1-f)*@value

  get: ->
    @display

  set: (@value) ->
    @last = @value

class InertialVector
  constructor: (x, y, z, damping, dt) ->
    @x = new InertialValue x, damping, dt
    @y = new InertialValue y, damping, dt
    @z = new InertialValue z, damping, dt

  accelerate: (x, y, z) ->
    @x.accelerate x
    @y.accelerate y
    @z.accelerate z

  integrate: ->
    @x.integrate()
    @y.integrate()
    @z.integrate()

  interpolate: (f) ->
    @x.interpolate f
    @y.interpolate f
    @z.interpolate f

  set: (x, y, z) ->
    if x instanceof Array
      @x.set x[0]
      @y.set x[1]
      @z.set x[2]
    else
      @x.set x
      @y.set y
      @z.set z





class DFIR.Camera extends DFIR.Object3D
  constructor: (@viewportWidth, @viewportHeight) ->
    @viewportWidth ?= gl.viewportWidth
    @viewportHeight ?= gl.viewportHeight
    @target = vec3.create()
    @fov = 45.0
    @up = vec3.fromValues 0.0, 1.0, 0.0
    @viewMatrix = mat4.create()
    @near = 0.01
    @far = 60.0
    @projectionMatrix = mat4.create()
    #@updateProjectionMatrix()
    #@updateViewMatrix()

  setFarClip: (@far) ->
    @updateProjectionMatrix()

  setNearClip: (@near) ->
    @updateProjectionMatrix()

  getViewMatrix: ->
    @viewMatrix

  getProjectionMatrix: ->
    @projectionMatrix


  getFrustumCorners: ->
    v = vec3.create()
    vec3.sub v, @target, @position
    vec3.normalize v, v
    w = vec3.create()
    vec3.cross w, viewVector, @up
    fov = @fov * Math.PI / 180.0
    ar = @viewportWidth / @viewportHeight

    Hnear = 2 * Math.tan(fov / 2.0) * @near
    Wnear = Hnear * ar

    Hfar = 2 * Math.tan(fov / 2.0) * @far
    Wfar = Hfar * ar

    Cnear = vec3.create()
    Cfar = vec3.create()

    vec3.add Cnear, @position, v
    vec3.scale Cnear, Cnear, @near

    vec3.add Cfar, @position, v
    vec3.scale Cfar, Cfar, @far

    #And now we get our points

    #Near Top Left = Cnear + (up * (Hnear / 2)) - (w * (Wnear / 2))

    #Near Top Right = Cnear + (up * (Hnear / 2)) + (w * (Wnear / 2))

    #Near Bottom Left = Cnear - (up * (Hnear / 2)) - (w * (Wnear /2))

    #Near Bottom Right = Cnear + (up * (Hnear / 2)) + (w * (Wnear / 2))

    #Far Top Left = Cfar + (up * (Hfar / 2)) - (w * Wfar / 2))

    #Far Top Right = Cfar + (up * (Hfar / 2)) + (w * Wfar / 2))

    #Far Bottom Left = Cfar - (up * (Hfar / 2)) - (w * Wfar / 2))

    #Far Bottom Right = Cfar - (up * (Hfar / 2)) + (w * Wfar / 2))

  getInverseProjectionMatrix: ->
    invProjMatrix = mat4.create()
    mat4.invert invProjMatrix, @projectionMatrix
    invProjMatrix

  getInverseViewProjectionMatrix: ->
    vpMatrix = mat4.create()
    mat4.multiply vpMatrix, @projectionMatrix, @viewMatrix
    mat4.invert vpMatrix, vpMatrix
    vpMatrix

  updateViewMatrix: ->
    mat4.identity @viewMatrix
    mat4.lookAt @viewMatrix, @position, @target, @up

  updateProjectionMatrix: () ->
    mat4.identity @projectionMatrix
    aspect = @viewportWidth / @viewportHeight
    mat4.perspective @projectionMatrix, @fov, aspect, @near, @far


class Pointer
  constructor: (@element, onMove) ->
    @onMove = onMove ? -> null

    @pressed = false
    @x = null
    @y = null

    @element.addEventListener 'mousedown', @mouseDown
    @element.addEventListener 'mouseup', @mouseUp
    @element.addEventListener 'mousemove', @mouseMove

  mouseDown: (event) =>
    @pressed = true

  mouseUp: (event) =>
    @pressed = false

  mouseMove: (event) =>
    rect = @element.getBoundingClientRect()
    x = event.clientX - rect.left
    y = event.clientY - rect.top

    if @x?
      dx = @x - x
      dy = @y - y
    else
      dx = 0
      dy = 0

    @x = x
    @y = y

    @onMove @x, @y, dx, dy

keymap = ({
    87: 'w'
    65: 'a'
    83: 's'
    68: 'd'
    81: 'q'
    69: 'e'
    37: 'left'
    39: 'right'
    38: 'up'
    40: 'down'
    13: 'enter'
    27: 'esc'
    32: 'space'
    8: 'backspace'
    16: 'shift'
    17: 'ctrl'
    18: 'alt'
    91: 'start'
    0: 'altc'
    20: 'caps'
    9: 'tab'
    49: 'key1'
    50: 'key2'
    51: 'key3'
    52: 'key4'
})

keys = {}

for value, name of keymap
    keys[name] = false

document.addEventListener 'keydown', (event) ->
    name = keymap[event.keyCode]
    keys[name] = true

document.addEventListener 'keyup', (event) ->
    name = keymap[event.keyCode]
    keys[name] = false

class DFIR.FPSCamera extends DFIR.Camera
  constructor: (@viewportWidth, @viewportHeight, @canvas) ->
    super()
    @origin = vec3.create()
    @rotation = 0
    @pitch = 0
    @rotVec = vec3.create()

    @pointer = new Pointer(@canvas, @pointerMove)

    @dt = 1/24
    @position = new InertialVector 0, 0, 0, 0.05, @dt

    @time = performance.now()/1000

    console.log @position

  setPosition: (vec) ->
    @position.set vec[0], vec[1], vec[2]

  pointerMove: (x, y, dx, dy) =>
    if @pointer.pressed
      @rotation -= dx * 0.01
      @pitch -= dy * 0.01

  step: ->
    now = performance.now()/1000
    while @time < now
      @time += @dt
      @position.integrate()
    f = (@time - now)/@dt
    @position.interpolate f

  cameraAcceleration: ->
    # acc = 100
    # vec3.set @rotVec, acc, 0, 0
    # vec3.rotateY @rotVec, @rotVec, @rotVec, -@rotation



    # if keys.a
    #   @position.accelerate -@rotVec[0], -@rotVec[1], -@rotVec[2]
    # if keys.d
    #   @position.accelerate @rotVec[0], @rotVec[1], @rotVec[2]

    # vec3.set @rotVec, 0, 0, acc
    # vec3.rotateY @rotVec, @rotVec, @rotVec, -@rotation
    # if keys.w
    #   @position.accelerate -@rotVec[0], -@rotVec[1], -@rotVec[2]
    # if keys.s
    #   @position.accelerate @rotVec[0], @rotVec[1], @rotVec[2]

  update: ->
    @cameraAcceleration()
    @step()

  updateViewMatrix: ->
    mat4.identity @viewMatrix
    mat4.rotateX @viewMatrix, @viewMatrix, @pitch
    mat4.rotateY @viewMatrix, @viewMatrix, @rotation
    if @position.x
      pos = vec3.fromValues( @position.x.display, @position.y.display, @position.z.display )
      
      mat4.translate @viewMatrix, @viewMatrix, pos



class DFIR.QuaternionCamera extends DFIR.Camera
  constructor: (@viewportWidth, @viewportHeight, @canvas) ->
    super(@viewportWidth, @viewportHeight)
    @sensitivity = 200.0
    @pointer = new Pointer( @canvas, @pointerMove )
    @rotx = 0.0
    @up = vec3.fromValues 0.0, 1.0, 0.0
    @view = vec3.fromValues 0.0, 0.0, 1.0
    @dt = 1/24
    @position = new InertialVector 0, 0, 0, 0.05, @dt
    @time = performance.now()/1000

  pointerMove: (x, y, dx, dy) =>
    if @pointer.pressed
      rotx = 0.0
      mx = dx / @sensitivity
      my = dy / @sensitivity
      @rotx += my
      pos = vec3.fromValues @position.x.display, @position.y.display, @position.z.display
      axis = vec3.create()
      vp = vec3.create()
      vec3.subtract(vp, @view, pos )
      vec3.cross(axis, vp, @up)
      vec3.normalize(axis, axis)
      @rotateCamera my, axis[0], axis[1], axis[2]
      @rotateCamera mx, 0.0, 1.0, 0.0

  rotateCamera: (angle, x, y, z) =>
    quat_view = quat.create()
    result = quat.create()
    tv = quat.create()
    tc = quat.create()
    temp = quat.fromValues x * Math.sin(angle/2), y * Math.sin(angle/2), z * Math.sin(angle/2), Math.cos(angle/2)
    quat_view = quat.fromValues @view[0], @view[1], @view[2], 0.0
    quat.multiply tv, temp, quat_view
    quat.conjugate temp, temp
    quat.multiply result, tv, temp
    vec3.set @view, result[0], result[1], result[2]

  updateViewMatrix: () ->
    target = vec3.fromValues @position.x.display, @position.y.display, @position.z.display
    look = vec3.clone @view
    #vec3.scale look, @view, 100.0
    vec3.add target, target, look
    mat4.lookAt @viewMatrix, [@position.x.display, @position.y.display, @position.z.display], target, @up

  getViewMatrix: () ->
    @viewMatrix

  getViewRotationMatrix: () ->
    vrMatrix = mat4.create()
    mat4.lookAt vrMatrix, [0.0, 0.0, 0.0], @view, @up
    vrMatrix

  setPosition: (vec) ->
    @position.set vec[0], vec[1], vec[2]

  step: ->
    now = performance.now()/1000
    while @time < now
      @time += @dt
      @position.integrate()
    f = (@time - now)/@dt
    @position.interpolate f

  cameraAcceleration: ->
    acc = 300.0
    vel = vec3.clone @view
    vec3.scale vel, vel, acc
    if keys.s
      @position.accelerate -vel[0], -vel[1], -vel[2]
    if keys.w
      @position.accelerate vel[0], vel[1], vel[2]

    vec3.cross vel, @view, @up
    vec3.scale vel, vel, acc

    if keys.a
      @position.accelerate -vel[0], -vel[1], -vel[2]
    if keys.d
      @position.accelerate vel[0], vel[1], vel[2]

  update: ->
    @cameraAcceleration()
    @step()


class DFIR.DirectionalLight extends DFIR.Object3D

	bind : (uniforms) ->
		gl.uniform3fv(uniforms.lightColor, @color)
		gl.uniform3fv(uniforms.lightDirection, @direction)


class DFIR.ShadowCamera extends DFIR.Camera
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
    @normalsTextureUnit = @createTexture(@half_ext.HALF_FLOAT_OES)
    #@depthTextureUnit = @createTexture()
    @depthComponent = @createDepthTexture()
    
    gl.framebufferTexture2D gl.FRAMEBUFFER, @mrt_ext.COLOR_ATTACHMENT0_WEBGL, gl.TEXTURE_2D, @albedoTextureUnit, 0
    gl.framebufferTexture2D gl.FRAMEBUFFER, @mrt_ext.COLOR_ATTACHMENT1_WEBGL, gl.TEXTURE_2D, @normalsTextureUnit, 0
    #gl.framebufferTexture2D gl.FRAMEBUFFER, @mrt_ext.COLOR_ATTACHMENT2_WEBGL, gl.TEXTURE_2D, @depthTextureUnit, 0
    gl.framebufferTexture2D gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, @depthComponent, 0
    
    status = gl.checkFramebufferStatus gl.FRAMEBUFFER
    console.log "GBuffer FrameBuffer status after initialization: #{status}";
    
    
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
    @material = new DFIR.Shader "fs_quad_vert" , "fs_quad_frag"
    @debug_uniform_location = @material.getUniform('DEBUG')
    
  createQuads: (num) ->
    tiles = Math.ceil(Math.sqrt(num))
    
    tileWidth = gl.viewportWidth / tiles
    tileHeight = gl.viewportHeight / tiles
    
    x = 0
    y = 0
    
    
    @quads = []
    #for i in [0 .. num]
    
  createQuad: (x, y, w, h) ->
    
    
    
    
  



class DFIR.Transform
	constructor: () ->
		@_translation = vec3.create()
		@_scale = vec3.fromValues 1.0, 1.0, 1.0
		@_rotation = quat.create()

	translate: (vec) ->
		vec3.add @_translation, @_translation, vec

	scale: (num) ->
		vec3.scale @_scale, @_scale, num

	scaleVector: (vec) ->
		vec3.multiply @_scale, @_scale, vec

	rotateX: (rad) ->
		quat.rotateX @_rotation, @_rotation, rad

	rotateY: (rad) ->
		quat.rotateY @_rotation, @_rotation, rad

	rotateZ: (rad) ->
		quat.rotateZ @_rotation, @_rotation, rad


	getMatrix: (dst) ->
		dst ?= mat4.create()
		mat4.fromRotationTranslationScale dst,@_rotation, @_translation, @_scale



class DFIR.SceneNode
	constructor: (@transform, @object=null) ->
		@localMatrix = mat4.create()
		@worldMatrix = mat4.create()
		@children = []
		@parent = null
		@visible = true
		@transform ?= new DFIR.Transform()

	# we shortbut to the internal transform class
	translate: (vec) ->
		@transform.translate vec

	scale: (num) ->
		@transform.scale num

	scaleVector: (vec) ->
		@transform.scaleVector vec

	rotateX: (rad) ->
		@transform.rotateX rad

	rotateY: (rad) ->
		@transform.rotateY rad

	rotateZ: (rad) ->
		@transform.rotateZ rad

	# walk this node and all children
	# calling callback on all visible
	walk: (callback) ->
		if @visible
			callback this
			for child in @children
				child.walk(callback)

			
			


	addChild: (child) ->
		child.setParent this

	setParent: (parent) ->
		if not parent?
			return
		if @parent and this in @parent.children
			@parent.children = @parent.chilren.filter (child) -> child isnt this
		if parent.children?
			parent.children.push @
		@parent = parent

	updateWorldMatrix: (parentMatrix) ->
		mat4.copy @localMatrix, @transform.getMatrix()
		if parentMatrix
			mat4.multiply @worldMatrix, parentMatrix, @localMatrix
		else
			mat4.copy @worldMatrix, @localMatrix 

		for child in @children
			child.updateWorldMatrix @worldMatrix


	attach: (@object) ->



class DFIR.Scene
	constructor:() ->
		@root = new DFIR.SceneNode()


	
class DFIR.Renderer
	constructor: (canvas) ->
		@ready = false
		@debug_view = 0
		@width = if canvas then canvas.width else 1280
		@height = if canvas then canvas.height else 720
		@sunPosition = vec3.fromValues -1.0, 0.0, 0.0
		@sunColor = vec3.fromValues 1.0, 1.0, 1.0
		@metallic = 1.0
		@roughness = 0.5
		@exposure = 1.0
		if !canvas?
			canvas = document.createElement 'canvas'
			document.body.appendChild canvas

		canvas.width = @width
		canvas.height = @height
		DFIR.gl = window.gl = canvas.getContext("webgl")
		gl.viewportWidth = canvas.width
		gl.viewportHeight = canvas.height
		@canvas = canvas
		@gbuffer = new DFIR.Gbuffer(1.0)
		@createTargets()
		@setDefaults()
		@drawCallCount = 0



	createTargets: () ->
		DFIR.ShaderLoader.load 'shaders/fs_quad_vert.glsl', 'shaders/fs_quad_frag.glsl', (program) =>
			@quad = new DFIR.FullscreenQuad()
			@quad.setMaterial ( new DFIR.Shader ( program ))
			@quad.material.showInfo()
			@ready = true


	setDefaults: () ->
		gl.clearColor 0.0, 0.0, 0.0, 0.0
		gl.enable gl.DEPTH_TEST
		gl.depthFunc gl.LEQUAL
		gl.depthMask true
		gl.clearDepth 1.0
		gl.enable gl.BLEND
		gl.blendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA
		gl.enable gl.CULL_FACE


	enableGBuffer: () ->
		@gbuffer.bind()
		gl.cullFace ( gl.BACK )
		gl.blendFunc( gl.ONE, gl.ZERO )
		gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )
		gl.enable(gl.CULL_FACE)


	updateGBuffer: (scene, camera) ->
		# render our gBuffer first
		@enableGBuffer()

		camera.updateViewMatrix()
		camera.updateProjectionMatrix()
		scene.root.updateWorldMatrix()


		dc = 0
		scene.root.walk (node) ->
			if node.object?
				if node.object.bind()
					#gl.uniform1f(node.object.material.getUniform('metallic'), @metallic)
					#gl.uniform1f(node.object.material.getUniform('roughness'), @roughness);
					node.object.draw camera, node.worldMatrix
					node.object.release()
					dc++

		@drawCallCount = dc

		@gbuffer.release()


	doLighting: (scene, camera) ->
		@quad.material.use()
		@quad.bind()

		gl.activeTexture(gl.TEXTURE0)
		gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getDepthTextureUnit())

		gl.activeTexture(gl.TEXTURE1)
		gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getNormalsTextureUnit())

		gl.activeTexture(gl.TEXTURE2)
		gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getAlbedoTextureUnit())

		gl.uniform1i(@quad.material.getUniform('depthTexture'), 0)
		gl.uniform1i(@quad.material.getUniform('normalsTexture'), 1)
		gl.uniform1i(@quad.material.getUniform('albedoTexture'), 2)
		gl.uniformMatrix4fv(@quad.material.getUniform('uViewMatrix'), false, camera.getViewMatrix())
		gl.uniformMatrix4fv(@quad.material.getUniform('uViewRotationMatrix'), false, camera.getViewMatrix())		

		gl.uniform3fv(@quad.material.getUniform('lightPosition'), @sunPosition)
		gl.uniform3fv(@quad.material.getUniform('lightColor'), @sunColor)
		gl.uniform1f(@quad.material.getUniform('exposure'), @exposure)
		#console.log(sunLight.position)

		#sunLight.bind(@quad.material.uniforms)

		gl.uniformMatrix4fv(@quad.material.getUniform('inverseProjectionMatrix'), false, camera.getInverseProjectionMatrix())
		gl.uniformMatrix4fv(@quad.material.getUniform('inverseViewProjectionMatrix'), false, camera.getInverseViewProjectionMatrix())

		#gl.uniform4f(@quad.material.getUniform('projectionParams'), projectionParams[0], projectionParams[1], projectionParams[2], projectionParams[3] )

		gl.uniform1i(@quad.material.getUniform('DEBUG'), @debug_view)

		gl.drawArrays(gl.TRIANGLES, 0, @quad.vertexBuffer.numItems)

		@quad.release()

	draw : (scene, camera) ->
		if @ready
			@updateGBuffer(scene, camera)
			@doLighting(scene, camera)
