class DFIR.Object2D




class DFIR.Object3D
  constructor: ->
    @position = vec3.create()
    @scale = vec3.create()

    vec3.set @scale, 1.0, 1.0, 1.0

    #@scale[0] = @scale[1] = @scale[2] = 1.0;
    #@rotationQuaternion = quat.create()
    @transformDirty = true
    @worldTransform = mat4.create()
    @worldViewMatrix = mat4.create()
    @normalMatrix = mat3.create()
    @worldViewProjectionMatrix = mat4.create()
    @children = []
    @visible = true

  getWorldTransform: () ->
    if @transformDirty is true
      @updateWorldTransform()
    @worldTransform

  getNormalMatrix: (viewMatrix) ->
    normalMatrix = mat3.create()
    mat3.getInverse normalMatrix, viewMatrix
    mat3.transpose normalMatrix, normalMatrix
    normalMatrix

  draw: (camera) ->
    if !@material or !@loaded
      return

    @material.use()
    #mat4.identity @worldViewMatrix
    #mat3.identity @normalMatrix
    @updateWorldTransform()
    mat4.multiply @worldViewMatrix, camera.getViewMatrix(), @worldTransform
    mat3.normalFromMat4 @normalMatrix, @worldViewMatrix
    
    @setMatrixUniforms(camera)

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

  setMatrixUniforms: (camera) ->
    if !@material
      return null

    gl.uniformMatrix4fv @material.getUniform( 'uMVMatrix' ), false, @worldViewMatrix
    gl.uniformMatrix4fv @material.getUniform( 'uPMatrix'), false, camera.getProjectionMatrix()
    gl.uniformMatrix4fv @material.getUniform('uViewMatrix'), false, camera.getViewMatrix()
    gl.uniformMatrix3fv @material.getUniform('uNormalMatrix'), false, @normalMatrix
    @setFloatUniform 'farClip', camera.far



  updateWorldTransform: (parentTransform) ->
    # reset ( should include parent here)
    mat4.identity @worldTransform
    mat4.translate @worldTransform, @worldTransform, @position
    mat4.scale @worldTransform, @worldTransform, @scale
    @transformDirty = false
    return

  setPosition: (pos) ->
    vec3.copy @position, pos
    #@position[0] = pos[0]
    #@position[1] = pos[1]
    #@position[2] = pos[2]
    @transformDirty = true

  setScale: (s) ->
    vec3.copy @scale, s
    #@scale[0] = s[0]
    #@scale[1] = s[1]
    #@scale[2] = s[2]
    @transformDirty = true

  visit: (func) ->
    if !@visible
      return
    func(@)
    for c in @children
      c.visit(func)

  update: ->
    if @transformDirty
      mat4.fromRotationTranslation @transform, @rotationQuaternion, @position
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
