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
