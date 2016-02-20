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

