# taken from threejs
mergeVertices = (vertices, faces) ->
  verticesMap = {}
  unique = []
  changes = []
  precisionPoints = 4
  precision = Math.pow(10, precisionPoints)

  for i in [0 ... vertices.length] by 1
    v = vertices[i]
    key = "#{Math.round(v[0] * precision)}_#{Math.round(v[1] * precision)}_#{Math.round(v[2]*precision)}"
    if verticesMap[key]?
      changes[i] = changes[verticesMap[key]]
    else
      verticesMap[key] = i
      unique.push vertices[i]
      changes[i] = unique.length - 1


class DFIR.Face
  constructor: (@a, @b, @c) ->



class DFIR.Geometry



  constructor: ->
    @indices = []
    @faces = []
    @vertices = []
    @normals = []
    @texCoords = [[]]
    @vertexBuffer = null
    @texCoordBuffers = []
    @indexBuffer = null
    @normalBuffer = null


  #createVertexBuffer: (data, itemSize, mode) ->
#    mode ?= gl.STATIC_DRAW
#    itemSize ?= 3
#    @vertexBuffers.push new DFIR.Buffer( data, itemSize, mode )
##
#  createTextureCoordinateBuffer: (data, itemSize, mode) ->
#    mode ?= gl.STATIC_DRAW
#    itemSize ?= 2
#    @textureCoodBuffers.push new DFIR.Buffer( data, itemSize, mode )
#
#  createIndexBuffer: (data, itemSize, mode) ->
#    mode ?= gl.STATIC_DRAW
#    itemSize ?= 1
#    @indexBuffers.push new DFIR.Buffer (data, itemSize, mode )


DFIR.Geometry.meshCache = {}

class DFIR.Plane extends DFIR.Geometry
  constructor: (size, detail=1) ->
    hs = size / 2
    @vertices = [
      -hs, 0, 0,
      hs, 0, 0,
      hs, 0, hs,
      -hs, 0, hs
    ]

    @indexes = [
      
    ]

class DFIR.CubeGeometry extends DFIR.Geometry
  constructor: (size, detail=1) ->
    super()


class DFIR.SphereGeometry extends DFIR.Geometry
  constructor: (rings) ->
    super()


VertexFormat =
	Position: 0x0001
	UV : 0x0002
	UV2 : 0x0004
	Normal : 0x0008
	Color: 0x0010


stringFromUint = (num) ->
	s = ""
	s += String.fromCharCode(num & 0xff)
	s += String.fromCharCode((num >> 8) & 0xff)
	s += String.fromCharCode((num >> 16) & 0xff)
	s += String.fromCharCode((num >> 24) & 0xff)
	return s

class DFIR.Mesh
	constructor : (url) ->
		@load url
		@ready = false

	load: (url) ->
		self = this
		vertComplete = false
		modelComplete = false

		# load vertex / index buffers
		vertXHR = new XMLHttpRequest()
		vertXHR.open('GET', url)
		vertXHR.responseType = 'arraybuffer'
		vertXHR.onload = () ->
			arrays = self.parseBinary @response
			self.compileBuffers arrays
			vertComplete = true
			self.ready = true

			if self.modelComplete
				something
		vertXHR.send null

		# load json stuff
		modelXHR = new XMLHttpRequest()

	parseBinary: (data) ->
		header = new Uint32Array data, 0, 3
		[magic, vertLength, indexLength] = header
		magic = stringFromUint magic

		if magic != 'DFIR'
			console.error "Magic String, she no match"

		console.log "#{vertLength} vertices, #{indexLength} indices"

		vertices = new Float32Array data, 3*4, vertLength
		indices = new Uint16Array data, (3*4) + (vertLength*4), indexLength

		@vertexLength = vertLength / 8

		@indexLength = indexLength

		console.log indices, indexLength

		[vertices, indices]

	parseJSON: (data) ->


	compileBuffers: (arrays) ->
		# vertexBuffer looks like this:

		# [vx, vy, vz, nx, ny, nz, uvx, uvy] = all float32.
		# therefore, stride = 4 + 4 + 4 + 4 + 4 + 4 + 4 + 4 = 32 bytes

		@vertexBuffer = gl.createBuffer()
		gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
		gl.bufferData gl.ARRAY_BUFFER, arrays[0], gl.STATIC_DRAW

		@indexBuffer = gl.createBuffer()
		gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @indexBuffer
		gl.bufferData gl.ELEMENT_ARRAY_BUFFER, arrays[1], gl.STATIC_DRAW

		gl.bindBuffer gl.ARRAY_BUFFER, null
		gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, null

		@vertexStride = 32

	bind: (positionAttrib, normalsAttrib, uvAttrib) ->

		if !@ready
			return false

		# bind our buffers
		gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
		gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @indexBuffer

		# bind to attribute pointers
		gl.enableVertexAttribArray positionAttrib
		gl.vertexAttribPointer positionAttrib, 3, gl.FLOAT, false, @vertexStride, 0

		gl.enableVertexAttribArray normalsAttrib
		gl.vertexAttribPointer normalsAttrib, 3, gl.FLOAT, true, @vertexStride, 12

		gl.enableVertexAttribArray uvAttrib
		gl.vertexAttribPointer uvAttrib, 2, gl.FLOAT, false, @vertexStride, 24

		return true


