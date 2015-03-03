class DFIR.Camera extends DFIR.Object3D
  constructor: () ->
    super()
    @fov = 45.0
    
  makeProjectionMatrix: (near=1.0, far=100.0) ->
    projMatrix = mat4.create()
    aspect = gl.viewportWidth / gl.viewportHeight
    mat4.perspective projMatrix, @fov, aspect, near, far
    projMatrix
    
  
    
  
    
    
