class DFIR.Object3D
  constructor: ->
    @position = vec3.create 0.0, 0.0, 0.0
    @rotationQuaternion = quat.create()
    @transformDirty = false
    @transform = mat4.create()
    @children = []
    
  setPosition: (pos) ->
    @position.x = pos.x
    @position.y = pos.y
    @position.z = pos.z
    @transformDirty = true
    
  update: ->
    if @transformDirty
      mat4.fromRotationTranslation @transform, @rotationQuaternion, @position
      @transformDirty = false
    
  addChild: (childObject) ->
    @children.push childObject
    
  removeChild: (childObject) ->
    @children.remove childObject
    
class DFIR.Scene extends DFIR.Object3D
  
    
  
