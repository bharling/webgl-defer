  #extension GL_EXT_draw_buffers : require
  #extension GL_OES_standard_derivatives : require
  precision highp float;
  varying vec3 vNormal;
  varying vec3 vEyeDirection;
  varying vec2 vTexCoords;
  varying vec2 depthClipSpace;

  uniform float farClip;
  uniform float nearClip;
  uniform mat3 uNormalMatrix;
  uniform sampler2D diffuseTex;
  uniform sampler2D normalTex;

  /*
    Pack floating point into color
    left in for curiosity's sake
  */
  /*
  vec4 pack (float v) {
	vec4 enc = vec4(1.0, 255.0, 65025.0, 160581375.0) * v;
  	enc = fract(enc);
  	enc -= enc.yzww * vec4(1.0/255.0,1.0/255.0,1.0/255.0,0.0);
  	return enc;
  }

  */

  // Begin no-tangents normal mapping
  mat3 cotangent_frame( vec3 N, vec3 p, vec2 uv ) {
  	// get edge vectors of the pixel triangle
    vec3 dp1 = dFdx( p );
    vec3 dp2 = dFdy( p );
    vec2 duv1 = dFdx( uv );
    vec2 duv2 = dFdy( uv );

    // solve the linear system
    vec3 dp2perp = cross( dp2, N );
    vec3 dp1perp = cross( N, dp1 );
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;

    // construct a scale-invariant frame
    float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );
    return mat3( T * invmax, B * invmax, N );
  }

  vec3 perturb_normal( vec3 N, vec3 V, vec2 texcoord ) {
    // assume N, the interpolated vertex normal and 
    // V, the view vector (vertex to eye)
    vec3 map = texture2D( normalTex, texcoord ).xyz;
//#ifdef WITH_NORMALMAP_UNSIGNED
    map = map * 255./127. - 128./127.;
//#endif
//#ifdef WITH_NORMALMAP_2CHANNEL
//    map.z = sqrt( 1. - dot( map.xy, map.xy ) );
//#endif
//#ifdef WITH_NORMALMAP_GREEN_UP
//     map.y = -map.y;
//#endif
    mat3 TBN = cotangent_frame( N, -V, texcoord );
    return normalize( TBN * map );
  }



  // end no-tangents normal mapping

  	vec4 encodeNormal ( vec3 n ) {
  		n = normalize(n);
  		vec2 enc = normalize(n.xy) * (sqrt(-n.z*0.5+0.5));
  		//enc = enc * 0.5 + 0.5;
  		return vec4(enc, 0.0, 1.0);
  	}

	//vec4 encodeNormal ( vec3 n ) {
	//	float p = sqrt(n.z * 8.0 + 8.0);
	//	return vec4(n.xy / p + 0.5, 0.0, 1.0);
	//}

  void main (void) {
    vec3 N = normalize(uNormalMatrix * vNormal);

    N = perturb_normal(N, vEyeDirection, vTexCoords );

    float metalness = 0.6;
    float roughness = 0.2;

    vec3 n =  N * 0.5 + 0.5;

  	//vec4 n = encodeNormal( _normal );

    gl_FragData[0] = texture2D( diffuseTex, vTexCoords);
    gl_FragData[1] = vec4( n.xyz, 1.0 );
  }
