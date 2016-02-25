precision mediump float;
varying vec2 vTexCoords;
varying float debug;
//uniform sampler2D depthTexture;
uniform sampler2D renderTexture;
uniform float exposure;

void main(void) {
  gl_FragColor = texture2D(renderTexture, vTexCoords);
}
