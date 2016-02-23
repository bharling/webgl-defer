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

    mat4.multiply temp, camera.getViewMatrix() , worldMatrix

    
    worldViewProjectionMatrix = mat4.clone camera.getProjectionMatrix()
    mat4.multiply(worldViewProjectionMatrix, worldViewProjectionMatrix, camera.getViewMatrix())
    mat4.multiply(worldViewProjectionMatrix, worldViewProjectionMatrix, worldMatrix)
    mat3.normalFromMat4 @normalMatrix, temp
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
