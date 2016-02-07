class DFIR.Object2D




class DFIR.Object3D
  constructor : (@resource)  ->
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


  bind: ->
    return @resource.bind()

  release: ->
    @resource.release()

  draw: (camera) ->
    @update()
    mat3.normalFromMat4 @normalMatrix, @transform
    worldViewProjectionMatrix = mat4.clone camera.getProjectionMatrix()
    mat4.multiply(worldViewProjectionMatrix, worldViewProjectionMatrix, camera.getViewMatrix())
    mat4.multiply(worldViewProjectionMatrix, worldViewProjectionMatrix, @transform)

    gl.uniformMatrix4fv @resource.material.getUniform( 'uWorldViewProjectionMatrix' ), false, worldViewProjectionMatrix
    gl.uniformMatrix3fv @resource.material.getUniform( 'uNormalMatrix'), false, @normalMatrix
    gl.uniform1f @resource.material.getUniform('nearClip'), camera.near
    gl.uniform1f @resource.material.getUniform('farClip'), camera.far

    gl.drawElements gl.TRIANGLES, @resource.vertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0


  #bindTextures: () ->
  #  gl.activeTexture gl.TEXTURE0
  #  gl.bindTexture gl.TEXTURE_2D, @material.diffuseMap 
  #  gl.uniform1i @material.getUniform('diffuseTex'), 0 
  #  gl.activeTexture gl.TEXTURE1 
  #  gl.bindTexture gl.TEXTURE_2D, @material.normalMap 
  #  gl.uniform1i @material.getUniform('normalTex'), 1



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
