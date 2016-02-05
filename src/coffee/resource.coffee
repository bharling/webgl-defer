loadJSON = (url, callback) ->
  key = md5(url)
  console.log key
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


class DFIR.Resource

	constructor: ( @url=null ) ->
		@id = DFIR.nextId()

	load: () ->

	unload: () ->

	bind: () ->




class DFIR.ModelResource extends DFIR.Resource

	constructor: (@url ) ->
		super()
		loadJSON @url, @onDataLoaded

	setMaterial : (shader) ->
    	@material = shader

	onDataLoaded: (data) =>
	    @vertexPositionBuffer = new DFIR.Buffer( new Float32Array( data.vertexPositions ), 3, gl.STATIC_DRAW )
	    @vertexTextureCoordBuffer = new DFIR.Buffer( new Float32Array( data.vertexTextureCoords ), 2, gl.STATIC_DRAW )
	    @vertexNormalBuffer = new DFIR.Buffer( new Float32Array( data.vertexNormals ), 3, gl.STATIC_DRAW )
	    @vertexIndexBuffer = new DFIR.Buffer( new Uint16Array( data.indices ), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER )
	    @loaded = true


	ready: () ->
		return @ready or @ready = (@loaded && @material && @material.ready)?

	bind: () ->
		if !@ready()
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



