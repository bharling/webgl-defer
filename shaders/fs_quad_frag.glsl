
precision mediump float;

uniform sampler2D depthTexture;
uniform sampler2D normalsTexture;
uniform sampler2D albedoTexture;

//uniform vec4 projectionParams;
uniform mat4 inverseProjectionMatrix;
uniform mat4 inverseViewProjectionMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uViewRotationMatrix;

// Directional Light
uniform vec3 lightPosition;
uniform vec3 lightColor;
uniform float exposure;

varying vec2 vTexCoords;

uniform vec2 resolution;

//uniform int DEBUG;

varying float debug;

#define PI 3.1415926535897932384626433832795

// vec3 reconstructViewSpacePosition( float p_depth, vec2 p_ndc ) {

// 	// these coords are uvs eg bottom left is 0,0
// 	p_ndc = p_ndc * 2.0 - 1.0;
// 	float x = p_ndc.x;
//   float y = (p_ndc.y);
//   vec4 vProjectedPos = vec4(x, y, p_depth * 2.0 - 1.0, 1.0);
//   // Transform by the inverse projection matrix
//   vec4 vPositionVS = vProjectedPos * inverseProjectionMatrix;
//   // Divide by w to get the view-space position
//   return vPositionVS.xyz / vPositionVS.w;


// }

vec3 reconstructViewSpacePosition( float depth, vec2 texcoord ) {
  vec4 clipSpaceLocation;
  clipSpaceLocation.x = texcoord.x * 2.0 - 1.0;
  clipSpaceLocation.y = texcoord.y * 2.0 - 1.0;
  clipSpaceLocation.z = depth * 2.0 - 1.0;
  clipSpaceLocation.w = 1.0;
  vec4 homogenousLocation = inverseViewProjectionMatrix * clipSpaceLocation;
  return homogenousLocation.xyz / homogenousLocation.w;
}

float chiGGX ( float v ) {
	return v > 0.0 ? 1.0 : 0.0;
}

float GGX_Distribution( vec3 n, vec3 h, float alpha ) {
	float NoH = dot(n,h);
	float alpha2 = alpha * alpha;
	float NoH2 = NoH * NoH;
	float den = NoH2 * alpha2 + (1.0-NoH2);
	return (chiGGX(NoH) * alpha2) / (PI * den * den);
}

vec3 decodeNormal( vec2 enc) {
  vec2 fenc = enc*4.0-2.0;
  float f = dot(fenc, fenc);
  float g = sqrt(1.0-f/4.0);
  vec3 n;
  n.xy = fenc * g;
  n.z = 1.0-f/2.0;
  return n;
}

float decodeDepth( vec4 rgba ) {
	// return dot( rgba, vec4( 1.0, 1.0/255.0, 1.0/65025.0, 1.0/160581375.0) );
  return rgba.r;
}


// Specular
// vec3 D(vec3 h) // Normal Distribution Function - GGX/Trowbridge-Reitz
// {
//     float alpha = roughness * roughness;
//     float NxH = dot(fNormal,h);
//     float alpha2 = alpha*alpha;
//     float t = ((NxH * NxH) * (alpha2 - 1.0) + 1.0);



// }

vec3 Gsub(vec3 v, vec3 fNormal, float roughness) // Sub Function of G
{
    //v = -v;
    float k = ((roughness + 1.0) * (roughness + 1.0)) / 8.0;
    return vec3(dot(fNormal, v) / ((dot(fNormal, v)) * (1.0 - k) + k));
}
// vec3 G(vec3 l, vec3 v, vec3 h) // Geometric Attenuation Term - Schlick Modified (k = a/2)
// {
//     return Gsub(l) * Gsub(v);
// }
// vec3 F(vec3 v, vec3 h, vec3 specularColor) // Fresnel - Schlick Modified (Spherical Gaussian Approximation)
// {
//     vec3 f0 = specularColor; // right?
//     return f0 + (1.0 - f0) * pow(2, (-5.55473 * (dot(v, h)) - 6.98316) * (dot(v, h)));
// }

float fresnel(vec3 direction, vec3 normal, bool invert) {
    vec3 nDirection = normalize( direction );
    vec3 nNormal = normalize( normal );
    vec3 halfDirection = normalize( nNormal + nDirection );

    float cosine = dot( halfDirection, nDirection );
    float product = max( cosine, 0.0 );
    float factor = invert ? 1.0 - pow( product, 5.0 ) : pow( product, 5.0 );

    return factor;
}

// vec3 specular(float dotNL, float dotNH, float dotNV, float dotVH, float roughness, vec3 realSpecularColor, vec3 viewDir, vec3 sunDir, vec3 normal)
// {
//     // ggx distribution
//     // http://stackoverflow.com/questions/23726495/physically-based-shader-not-producing-desired-results
//     float alpha = roughness * roughness;
//     float alpha2 = alpha*alpha;
//     float t = ((dotNH * dotNH) * (alpha2 - 1.0) + 1.0);
//     vec3 D = vec3(alpha2 / (PI * t * t));

//     // fresnel - quick and dirty
//     // http://www.standardabweichung.de/code/javascript/webgl-glsl-fresnel-schlick-approximation
//     float product = max(dotNH, 0.0);
//     float F = pow( product, 5.0 );

//     vec3 G = Gsub( sunDir, normal, roughness ) * Gsub( viewDir, normal, roughness );

//     return D * F * G / 4.0 * dotNL * dotNV;


//     //return (D(halfVector) * F(eyeVector, halfVector) * G(lightVector, eyeVector, halfVector)) / 4 * ((dot(fNormal, lightVector)) * (dot(fNormal, eyeVector)));
// }

vec3 albedo( vec3 realAlbedo ) {
  return realAlbedo / PI;
}

float saturate ( float v ) {
  return clamp(v, 0.0, 1.0);
}

vec4 computeLighting(vec3 normal, vec3 diffuse, vec3 sunColor, float strength, vec3 sunDir, vec3 viewDir, float attenuation, float roughness, float metallic) {


  vec3 H = normalize(normalize(viewDir)+normalize(sunDir));


  float dotNL = saturate(dot(normal, sunDir));

  float dotNH = saturate(dot(normal, H));
  float dotNV = saturate(dot(normal, viewDir));
  float dotVH = saturate(dot(viewDir, H));
  float alpha = max(0.001, roughness * roughness);

  //apply gamma correction for the colors
  vec3 g_diffuse = pow(diffuse, vec3(2.2));
  vec3 g_lightColor = lightColor;

  // Lerp with metallic value to find the good diffuse and specular.
  vec3 realAlbedo = g_diffuse - g_diffuse * metallic;

  // 0.03 default specular value for dielectric.
  vec3 realSpecularColor = mix(vec3(0.03), g_diffuse, metallic);

  //calculate the diffuse and specular components
  vec3 albedoDiffuse = albedo(realAlbedo);
  //vec3 specular = specular(dotNL, dotNH, dotNV,
  //                          dotVH, roughness, realSpecularColor, viewDir, sunDir, normal);

  float alpha2 = alpha*alpha;
  float t = ((dotNH * dotNH) * (alpha2 - 1.0) + 1.0);
  vec3 D = vec3(alpha2 / (PI * t * t));

  // fresnel - quick and dirty
  // http://www.standardabweichung.de/code/javascript/webgl-glsl-fresnel-schlick-approximation
  float product = max(dotNH, 0.0);
  float F = pow( product, 5.0 );

  vec3 G = Gsub( sunDir, normal, roughness ) * Gsub( viewDir, normal, roughness );

  vec3 specular =  D * F * G / 4.0 * dotNL * dotNV;

  //final result
  vec3 finalColor = lightColor * dotNL
                   * (albedoDiffuse * (1.0 - specular) + specular);

  return vec4(attenuation * (strength * finalColor), 1.0);

}


vec4 reinhardt (vec4 col) {
  col *= exposure;
  col = col/(1.0+col);
  vec3 ret = pow(col.xyz, vec3(1.0/2.2));
  return vec4(ret, 1.0);

}

void main (void) {

	float DEBUG = floor(debug);

	const vec3 specularColor = vec3(1.0);
	const float specularExponent = 15.0;



  vec4 depthSample = texture2D(depthTexture, vTexCoords);

  if (DEBUG == 1.0) {
  	gl_FragColor = vec4(depthSample.xyz, 1.0);
  	return;
  }


  vec4 normalsSample = texture2D(normalsTexture, vTexCoords);

  if (DEBUG == 2.0) {
  	gl_FragColor = normalsSample;
  	return;
  }

  vec3 matColor = texture2D( albedoTexture, vTexCoords).xyz;
  matColor = pow ( matColor, vec3(2.2));

  if (DEBUG == 3.0) {
  	gl_FragColor = vec4(matColor, 1.0);
  	return;
  }

  float decodedDepth = decodeDepth(depthSample);

  vec4 decodedNormal = vec4(decodeNormal(normalsSample.xy),1.0);
  float metallic = normalsSample.z;
  float roughness = normalsSample.w;

  if (DEBUG == 4.0) {
    gl_FragColor = decodedNormal;
    return;
  }

  if (DEBUG == 5.0) {
  	gl_FragColor = vec4(metallic, roughness, 1.0, 1.0);
  	return;
  }


  // vec4 decodedNormal = vec4(normalsSample.xyz * 2.0 - 1.0, 1.0 ); //vec4(decodeNormal(  normalsSample ), 1.0);

  




  vec3 viewPosition = reconstructViewSpacePosition( depthSample.r, vTexCoords );

  if (DEBUG == 6.0) {
  	gl_FragColor = vec4((viewPosition), 1.0);
  	return;
  }

  vec3 sunColor = lightColor.xyz;
  float strength = 1.5;
  vec3 sunDir = lightPosition; //normalize(uViewRotationMatrix * vec4(-lightPosition.xyz, 1.0)).xyz;
  float attenuation = 0.6;

  //vec3 normal, vec3 diffuse, float sunColor, float strength, vec3 sunDir, vec3 viewDir, float attenuation, float roughness, float metallic

  vec3 ld = normalize(sunDir);
  vec3 vp = normalize(viewPosition);

  vec4 color = computeLighting(decodedNormal.xyz, matColor, sunColor, strength, ld, vp, attenuation, roughness, metallic);

  //color += vec4(0.0001, 0.0001, 0.0002, 0.0);

  gl_FragColor = reinhardt( color );


  // vec3 worldPosition = viewPosition;

  // vec3 eyeDirection = normalize(viewPosition);

  // vec4 _sundir = normalize(vec4(lightPosition.xyz, 1.0));

  // vec3 sunDir = _sundir.xyz;

  // vec3 H = normalize(eyeDirection+-sunDir);
  // vec3 N = decodedNormal.xyz;

  // vec3 reflectionDirection = reflect(decodedNormal.xyz, sunDir );

  // float specVal = pow(max(dot(reflectionDirection, eyeDirection), 0.0), specularExponent);

  // //float specVal = pow( clamp( dot(N, H), 0.0, 1.0 ), 5.0 );

  // float base = 1.0 - dot(eyeDirection, H);
  // float exponential = pow(base, 5.0);
  // float fresnel = exponential + 1.2 * (1.0 - exponential);
  // specVal *= fresnel;

  // float sun = clamp( dot( decodedNormal.xyz, sunDir), 0.0, 1.0);

  // float ind = clamp( dot( decodedNormal.xyz, normalize(sunDir*vec3(-1.0,0.0,-1.0)) ), 0.0, 1.0 );

  // float sky = clamp( 0.5 + 0.5*decodedNormal.y, 0.0, 1.0 );

  // vec3 lin = sun * vec3(1.64, 1.27, 0.99);



  // //lin += sky*vec3(0.16,0.20,0.28);

  // //lin += ind*vec3(0.40,0.28,0.20) * 0.2;

  // //lin += specularColor * specVal;

  // vec3 color = matColor * lin;

  // //color = mix(color, specularColor, specVal);

  // color = pow( color, vec3(1.0/2.2) );



  // gl_FragColor = vec4(color, 1.0);

  // //gl_FragColor = decodedNormal;
  // //gl_FragColor = mix(d, decodedNormal, vTexCoords.x > 0.5 ? 1.0 : 0.0);
}
