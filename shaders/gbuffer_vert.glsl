attribute vec3 aVertexNormal;
attribute vec3 aVertexPosition;
attribute vec2 aVertexTextureCoords;
  
  uniform mat4 uWorldViewProjectionMatrix;
  uniform mat3 uNormalMatrix;
  uniform float nearClip;
  uniform float farClip;
  
  
  varying vec2 vTexCoords;

  varying vec3 vNormal;
  varying vec3 vEyeDirection;
  
  void main (void) {
      const float C = 1.0;

      vTexCoords = aVertexTextureCoords;
      gl_Position = uWorldViewProjectionMatrix * vec4(aVertexPosition, 1.0);

      gl_Position.z = log(C* gl_Position.z + 1.0) / log(C*farClip + 1.0) * gl_Position.w;
      vEyeDirection = -gl_Position.xyz;
      //gl_Position.z = log(gl_Position.z / nearClip) / log(farClip / nearClip);
      //depthClipSpace = gl_Position.zw;
      
      vNormal = aVertexNormal;
      //vNormal = aVertexNormal;
      
  }