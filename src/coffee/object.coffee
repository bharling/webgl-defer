class DFIR.Object3D
  constructor: ->
    @position = vec3.create()
    @scale = vec3.create()
    @rotationQuaternion = quat.create()
    @transformDirty = false
    @transform = mat4.create()
    @children = []
    @visible = true
    
  setPosition: (pos) ->
    @position.x = pos.x
    @position.y = pos.y
    @position.z = pos.z
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
    
  
    
  
