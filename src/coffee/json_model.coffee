loadJSON = (url, callback) ->
  request = new XMLHttpRequest()
  request.open 'GET', url
  console.log "Loading json: #{url}"
  
  request.onreadystatechange = () ->
    if request.readyState is 4
      callback JSON.parse( request.responseText )
  request.send()




class DFIR.JSONGeometry extends DFIR.Object3D
  constructor: (url) ->
    loadJSON url, @onDataLoaded
    @material = null
    @loaded = false
    
    
  setMaterial : (shader) ->
    @material = shader
    
  
    
  bind : ->
    if !@material or !@loaded
      return false
    
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexPositionBuffer.get()
    gl.vertexAttribPointer @material.getAttribute( 'aVertexPosition'), @vertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0
    
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexTextureCoordBuffer.get()
    gl.vertexAttribPointer @material.getAttribute( 'aVertexTextureCoords'), @vertexTextureCoordBuffer.itemSize, gl.FLOAT, false, 0, 0
    
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexNormalBuffer.get()
    gl.vertexAttribPointer @material.getAttribute( 'aVertexNormal' ), @vertexNormalBuffer.itemSize, gl.FLOAT, false, 0, 0
    return true 
  
  setMatrixUniforms: (mvMatrix, pMatrix) ->
    if !@material
      return null
      
    gl.uniformMatrix4fv @material.getUniform( 'uMVMatrix' ), false, mvMatrix
    gl.uniformMatrix4fv @material.getUniform( 'uPMatrix'), false, pMatrix
    
  setFloatUniform: (name, val) ->
    gl.uniform1f @material.getUniform(name), val
    
  draw : ->
    if !@material or !@loaded
      return
    @material.use()
    gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @vertexIndexBuffer.get()
    gl.drawElements gl.TRIANGLES, @vertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0
    
  onDataLoaded: (data) =>
    @vertexPositionBuffer = new DFIR.Buffer( new Float32Array( data.vertexPositions ), 3, gl.STATIC_DRAW )
    @vertexTextureCoordBuffer = new DFIR.Buffer( new Float32Array( data.vertexTextureCoords ), 2, gl.STATIC_DRAW )
    @vertexNormalBuffer = new DFIR.Buffer( new Float32Array( data.vertexNormals ), 3, gl.STATIC_DRAW )
    @vertexIndexBuffer = new DFIR.Buffer( new Uint16Array( data.indices ), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER )
    @loaded = true
    
    
  @load: (url) ->
    new DFIR.JSONGeometry url
    
    
