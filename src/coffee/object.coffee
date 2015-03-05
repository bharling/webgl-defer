class DFIR.Object3D
  constructor: ->
    @position = vec3.create()
    @scale = vec3.create()
    #@rotationQuaternion = quat.create()
    @transformDirty = true
    @worldTransform = mat4.create()
    @children = []
    @visible = true
    
  getWorldTransform: () ->
    if @transformDirty is true
      @updateWorldTransform()
      console.log @, @worldTransform
    @worldTransform
      
  updateWorldTransform: (parentTransform) ->
    mat4.identity @worldTransform
    mat4.translate @worldTransform, @position
    mat4.scale @worldTransform, @scale
    @transformDirty = false
    return
    
  setPosition: (pos) ->
    @position[0] = pos[0]
    @position[1] = pos[1]
    @position[2] = pos[2]
    @transformDirty = true
    
  setScale: (s) ->
    @scale[0] = s[0]
    @scale[1] = s[1]
    @scale[2] = s[2]
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
    
  
    
  
