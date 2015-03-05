class DFIR.Camera extends DFIR.Object3D
  constructor: () ->
    super()
    @target = vec3.create()
    @fov = 45.0
    @up = vec3.create [0.0, 1.0, 0.0]
    @viewMatrix = mat4.create()
    @near = 0.0
    @far = 100.0
    @updateViewMatrix()
    @projectionMatrix = mat4.create()
    @updateProjectionMatrix()
    
  setFarClip: (@far) ->
    @updateProjectionMatrix()
    
  setNearClip: (@near) ->
    @updateProjectionMatrix()
    
  getViewMatrix: ->
    @viewMatrix
    
  getProjectionMatrix: ->
    @projectionMatrix
    
  getInverseProjectionMatrix: ->
    invProjMatrix = mat4.create()
    mat4.inverse @projectionMatrix, invProjMatrix
    invProjMatrix
    
  updateViewMatrix: ->
    mat4.identity @viewMatrix
    mat4.lookAt @position, @target, @up, @viewMatrix
    
  updateProjectionMatrix: () ->
    mat4.identity @projectionMatrix
    aspect = gl.viewportWidth / gl.viewportHeight
    mat4.perspective 45, gl.viewportWidth / gl.viewportHeight, 0.1, 100.0, @projectionMatrix
    
    
  
    
  
    
    
