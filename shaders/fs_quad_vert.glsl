  attribute vec2 aVertexPosition;
  attribute vec2 aVertexTextureCoords;
  
  varying vec2 vTexCoords;
  
  uniform int DEBUG;
  varying float debug;
  
  void main( void ) {
    gl_Position = vec4(aVertexPosition,0.0, 1.0);
    debug = float(DEBUG);
    vTexCoords = aVertexTextureCoords;
  }