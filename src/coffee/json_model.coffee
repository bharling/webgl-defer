loadJSON = (url, callback) ->
  key = md5(url)
  if DFIR.Geometry.meshCache[key]?
    console.log 'Not loading #{url}'
    callback DFIR.Geometry.meshCache[key]
    return

  request = new XMLHttpRequest()
  request.open 'GET', url

  request.onreadystatechange = () ->
    if request.readyState is 4
      result = JSON.parse( request.responseText )
      DFIR.Geometry.meshCache[key] = result
      callback JSON.parse( request.responseText )
  request.send()



class DFIR.JSONGeometry extends DFIR.Object3D
  constructor: (url) ->
    super()
    loadJSON url, @onDataLoaded
    @material = null
    @loaded = false


  setMaterial : (shader) ->
    @material = shader



  bind : ->
    if !@material or !@loaded or !@material.diffuseMapLoaded or !@material.normalMapLoaded
      return false

    @material.use()

    positionAttrib = @material.getAttribute( 'aVertexPosition')
    texCoordsAttrib = @material.getAttribute( 'aVertexTextureCoords')
    normalsAttrib = @material.getAttribute( 'aVertexNormal' )


    gl.enableVertexAttribArray positionAttrib
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexPositionBuffer.get()
    gl.vertexAttribPointer positionAttrib, @vertexPositionBuffer.itemSize, gl.FLOAT, false, 12, 0

    gl.enableVertexAttribArray texCoordsAttrib
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexTextureCoordBuffer.get()
    gl.vertexAttribPointer texCoordsAttrib, @vertexTextureCoordBuffer.itemSize, gl.FLOAT, false, 8, 0

    gl.enableVertexAttribArray normalsAttrib
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexNormalBuffer.get()
    gl.vertexAttribPointer normalsAttrib, @vertexNormalBuffer.itemSize, gl.FLOAT, false, 12, 0
    return true

  release: ->
    gl.bindBuffer gl.ARRAY_BUFFER, null

  #setMatrixUniforms: (mvMatrix, pMatrix) ->
  #  if !@material
  #    return null
  #
  #  gl.uniformMatrix4fv @material.getUniform( 'uMVMatrix' ), false, mvMatrix
  #  gl.uniformMatrix4fv @material.getUniform( 'uPMatrix'), false, pMatrix

  setFloatUniform: (name, val) ->
    gl.uniform1f @material.getUniform(name), val

  setVec4Uniform: (name, x, y, z, w) ->
    gl.uniform4f @material.getUniform(name), x, y, z, w


  #draw : ->
  #  if !@material or !@loaded
  #    return
  #
  #  gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @vertexIndexBuffer.get()
  #  gl.drawElements gl.TRIANGLES, @vertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0

  onDataLoaded: (data) =>

    if data.vertexPositions?
      @vertexPositionBuffer = new DFIR.Buffer( new Float32Array( data.vertexPositions ), 3, gl.STATIC_DRAW )
      @vertexTextureCoordBuffer = new DFIR.Buffer( new Float32Array( data.vertexTextureCoords ), 2, gl.STATIC_DRAW )
      @vertexNormalBuffer = new DFIR.Buffer( new Float32Array( data.vertexNormals ), 3, gl.STATIC_DRAW )
      @vertexIndexBuffer = new DFIR.Buffer( new Uint16Array( data.indices ), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER )
      @loaded = true
    else if data.faces?
      @parseThreeJSModel data

      #@vertexIndexBuffer = new DFIR.Buffer( new Float32Array( data.faces ), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER )
      #@loaded = true

  parseThreeJSModel: (data) =>

    isBitSet = (value, position) ->
      return value & ( 1 << position )

    vertices = data.vertices
    uvs = data.uvs
    indices = []
    normals = data.normals

    vertexNormals = []
    vertexUvs = []
    vertexPositions = []

    @vertexPositionBuffer = new DFIR.Buffer( new Float32Array( data.vertices ), 3, gl.STATIC_DRAW )
    @vertexTextureCoordBuffer = new DFIR.Buffer( new Float32Array( data.uvs[0] ), 2, gl.STATIC_DRAW )

    numUvLayers = data.uvs.length
    faces = data.faces

    zLength = faces.length
    offset = 0

    while offset < zLength
      type = faces[offset++]
      isQuad              = isBitSet( type, 0 )
      hasMaterial         = isBitSet( type, 1 )
      hasFaceVertexUv     = isBitSet( type, 3 )
      hasFaceNormal       = isBitSet( type, 4 )
      hasFaceVertexNormal = isBitSet( type, 5 )
      hasFaceColor       = isBitSet( type, 6 )
      hasFaceVertexColor  = isBitSet( type, 7 )

      #console.log type

      if isQuad
        indices.push faces[ offset ]
        indices.push faces[ offset + 1 ]
        indices.push faces[ offset + 3 ]
        indices.push faces[ offset + 1 ]
        indices.push faces[ offset + 2 ]
        indices.push faces[ offset + 3 ]
        offset += 4

        if hasMaterial
          offset++

        if hasFaceVertexUv
          for i in [0 ... numUvLayers] by 1
            uvLayer = data.uvs[i]
            for j in [0 ... 4] by 1
              uvIndex = faces[offset++]
              u = uvLayer[ uvIndex * 2 ]
              v = uvLayer[ uvIndex * 2 + 1 ]

              if j isnt 2
                vertexUvs.push u
                vertexUvs.push v
              if j isnt 0
                vertexUvs.push u
                vertexUvs.push v

        if hasFaceNormal
          offset++

        if hasFaceVertexNormal
          for i in [0 ... 4] by 1
              normalIndex = faces[ offset++ ] * 3
              normal = [ normalIndex++, normalIndex++, normalIndex ]
              if i isnt 2
                vertexNormals.push normals[normal[0]]
                vertexNormals.push normals[normal[1]]
                vertexNormals.push normals[normal[2]]
              if i isnt 0
                vertexNormals.push normals[normal[0]]
                vertexNormals.push normals[normal[1]]
                vertexNormals.push normals[normal[2]]

        if hasFaceColor
          offset++

        if hasFaceVertexColor
          offset += 4
      else
        indices.push faces[offset++]
        indices.push faces[offset++]
        indices.push faces[offset++]

        if hasMaterial
          offset++
        if hasFaceVertexUv
          for i in [0 ... numUvLayers]
            uvLayer = data.uvs[i]
            for j in [0 ... 3]
              uvIndex = faces[offset++]
              u = uvLayer[ uvIndex * 2 ]
              v = uvLayer[ uvIndex * 2 + 1 ]
              if j isnt 2
                vertexUvs.push u
                vertexUvs.push v
              if j isnt 0
                vertexUvs.push u
                vertexUvs.push v

        if hasFaceNormal
          console.log "hasFaceNormal"
          offset++

        if hasFaceVertexNormal
          for i in [0 ... 3] by 1
            normalIndex = faces[ offset++ ]
            vertexNormals.push normals[normalIndex++]
            vertexNormals.push normals[normalIndex++]
            vertexNormals.push normals[normalIndex]

            #vertexNormals.push 0.0
            #vertexNormals.push 1.0
            #vertexNormals.push 0.0


        if hasFaceColor
          offset++

        if hasFaceVertexColor
          offset +=3

    @vertexNormalBuffer = new DFIR.Buffer( new Float32Array( vertexNormals ), 3, gl.STATIC_DRAW )
    @vertexIndexBuffer = new DFIR.Buffer( new Uint16Array( indices ), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER )
    @loaded=true



  normalizeNormals: (normals) ->
    for i in [0 ... normals.length] by 3

      x = normals[ i ];
      y = normals[ i + 1 ]
      z = normals[ i + 2 ]

      n = 1.0 / Math.sqrt( x * x + y * y + z * z )

      normals[ i ] *= n
      normals[ i + 1 ] *= n
      normals[ i + 2 ] *= n
    return normals


  @load: (url) ->
    new DFIR.JSONGeometry url
