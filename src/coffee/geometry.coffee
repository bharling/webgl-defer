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

class DFIR.CubeGeometry extends DFIR.Geometry
  constructor: (size, detail=1) ->
    super()


class DFIR.SphereGeometry extends DFIR.Geometry
  constructor: (rings) ->
    super()
