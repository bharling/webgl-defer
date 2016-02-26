precision mediump float;
varying vec2 vTexCoords;
varying float debug;
//uniform sampler2D depthTexture;
uniform sampler2D renderTexture;
uniform float exposure;

vec4 reinhardt (vec4 col) {
  col *= exposure;
  col = col/(1.0+col);
  vec3 ret = pow(col.xyz, vec3(1.0/2.2));
  return vec4(ret, 1.0);

}

void main(void) {
  gl_FragColor = reinhardt( texture2D(renderTexture, vTexCoords) );
}
