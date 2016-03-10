precision mediump float;
varying vec2 vTexCoords;
varying float debug;
//uniform sampler2D depthTexture;
uniform sampler2D renderTexture;
uniform float exposure;
uniform int tonemap;

float A = 0.15;
float B = 0.50;
float C = 0.10;
float D = 0.20;
float E = 0.02;
float F = 0.30;
float W = 11.2;

vec3 Uncharted2Tonemap(vec3 x) {
  return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

vec4 uncharted (vec3 col) {
  col *= exposure;

  float ExposureBias = 2.0;
  vec3 curr = Uncharted2Tonemap(ExposureBias*col.xyz);

  vec3 whiteScale = 1.0/Uncharted2Tonemap(vec3(W));
  vec3 color = curr*whiteScale;

  color = pow(color, vec3(1.0/2.2));
  return vec4(color, 1.0);
}

vec4 reinhardt (vec4 col) {
  col *= exposure;
  col = col/(1.0+col);
  vec3 ret = pow(col.xyz, vec3(1.0/2.2));
  return vec4(ret, 1.0);
}

vec4 linear( vec4 col ) {
  col *= exposure;
  vec3 retCol = pow(col.xyz, vec3(1.0/2.2));
  return vec4(retCol, 1.0);
}

vec4 hejl_dawson( vec4 col ) {
  col *= exposure;
  vec3 x = max(vec3(0.0), col.xyz-0.004);
  vec3 retCol = (x * (6.2*x+0.5)) / (x*(6.2*x+1.7)+0.06);
  return vec4(retCol, 1.0);
}


void main(void) {
  vec4 fragment = texture2D(renderTexture, vTexCoords);
  vec4 color = vec4(0.0,0.0,0.0,1.0);
  if (tonemap ==3) {
    color = uncharted( fragment.xyz);
  }

  if (tonemap==2) {
    color = hejl_dawson( fragment );
  }

  if (tonemap==1) {
    color = linear( fragment );
  }

  if (tonemap == 0) {
    color = reinhardt( fragment );
  }

  gl_FragColor = color;

}
