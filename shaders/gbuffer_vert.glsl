attribute vec3 aVertexNormal;
attribute vec3 aVertexPosition;
attribute vec2 aVertexTextureCoords;
  
  uniform mat4 uMVMatrix;
  uniform mat4 uPMatrix;
  uniform mat3 uNormalMatrix;
  
  varying vec2 vTexCoords;
  varying vec2 depthClipSpace;
  varying vec3 vNormal;
  varying vec3 vEyeDirection;
  
  void main (void) {
      vTexCoords = aVertexTextureCoords;
      gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
      depthClipSpace = gl_Position.zw;
      
      vNormal = uNormalMatrix * aVertexNormal;
      vNormal = aVertexNormal;
      vEyeDirection = -gl_Position.xyz;
  }