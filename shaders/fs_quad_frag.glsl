  precision mediump float;
  
  uniform sampler2D depthTexture;
  uniform sampler2D normalsTexture;
  uniform sampler2D albedoTexture;
  
  uniform vec4 projectionParams;
  uniform mat4 inverseProjectionMatrix;
  uniform mat4 uViewMatrix;
  
  varying vec2 vTexCoords;
  
  //uniform int DEBUG;
  
  varying float debug;
  
  #define PI 3.1415926535897932384626433832795
  
  vec3 reconstructViewSpacePosition( float p_depth, vec2 p_ndc ) {
  
  	// these coords are uvs eg bottom left is 0,0
  	//p_ndc = p_ndc * 2.0 - 1.0;
  	//float x = p_ndc.x;
    //float y = p_ndc.y;
    //vec4 vProjectedPos = vec4(x, y, p_depth, 1.0);
    // Transform by the inverse projection matrix
    //vec4 vPositionVS = vProjectedPos * inverseProjectionMatrix;  
    // Divide by w to get the view-space position
    //return vPositionVS.xyz / vPositionVS.w;  
  	
  	p_ndc = p_ndc * 2.0 - 1.0;
  	p_depth = p_depth * 2.0 - 1.0;
  	
  	float viewDepth = projectionParams.w / (depth - projectionParams.z);

    return vec3((p_ndc * viewDepth) / projectionParams.xy, viewDepth);
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
  
  
  //vec3 decodeNormal ( vec2 enc ) {
  	//enc = enc * 2.0 - 1.0;
  //	vec2 fenc = enc * 4.0 - 2.0;
  //	float f = dot(fenc, fenc);
  //	float g = sqrt(1.0-f/4.0);
  //	vec3 n;
  //	n.xy = fenc*g;
  //	n.z = 1.0-f/2.0;
  //	
  //	//n = n * 2.0 - 1.0;
  //	return n;
  //}
  
  vec3 decodeNormal ( vec4 enc ) {
  	vec4 nn = enc*vec4(2.0,2.0,0.0,0.0) + vec4(-1.0, -1.0, 1.0, -1.0);
  	float l = dot(nn.xyz, -nn.xyw);
  	nn.z = l;
  	nn.xy *= sqrt(l);
  	return nn.xyz * 2.0 + vec3(0.0,0.0,-1.0);
  }
  
  float decodeDepth( vec4 rgba ) {
  	return dot( rgba, vec4( 1.0, 1.0/255.0, 1.0/65025.0, 1.0/160581375.0) );
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
    
    if (DEBUG == 4.0) {
    	gl_FragColor = vec4(decodedDepth, decodedDepth, decodedDepth, 1.0);
    	return;
    }
    
    
    vec4 decodedNormal = vec4(decodeNormal(  normalsSample ), 1.0);
    
    if (DEBUG == 5.0) {
    	gl_FragColor = decodedNormal;
    	return;
    }
    
    
    vec3 viewPosition = reconstructViewSpacePosition( decodedDepth, vTexCoords );
    
    if (DEBUG == 6.0) {
    	gl_FragColor = vec4((viewPosition), 1.0);
    	return;
    }
    
    
    vec3 worldPosition = viewPosition;
    
    vec3 eyeDirection = normalize(viewPosition);
    
    vec4 _sundir = uViewMatrix * normalize(vec4(0.0, -1.0, 0.0, 1.0));
    
    vec3 sunDir = _sundir.xyz;
    
    vec3 H = normalize(eyeDirection+sunDir);
    vec3 N = decodedNormal.xyz;
    
    vec3 reflectionDirection = reflect(decodedNormal.xyz, sunDir );
    
    float specVal = pow(max(dot(reflectionDirection, eyeDirection), 0.0), specularExponent);
    
    //float specVal = pow( clamp( dot(N, H), 0.0, 1.0 ), 5.0 );
    
    float base = 1.0 - dot(eyeDirection, H);
    float exponential = pow(base, 5.0);
    float fresnel = exponential + 1.2 * (1.0 - exponential);
    specVal *= fresnel;
    
    float sun = clamp( dot( decodedNormal.xyz, sunDir), 0.0, 1.0);
    
    float ind = clamp( dot( decodedNormal.xyz, normalize(sunDir*vec3(-1.0,0.0,-1.0)) ), 0.0, 1.0 );
    
    float sky = clamp( 0.5 + 0.5*decodedNormal.y, 0.0, 1.0 );
    
    vec3 lin = sun * vec3(1.64, 1.27, 0.99);
    
    
    
    lin += sky*vec3(0.16,0.20,0.28);
    
    lin += ind*vec3(0.40,0.28,0.20);
    
    //lin += specularColor * specVal;
    
    vec3 color = matColor * lin;
    
    //color = mix(color, specularColor, specVal);
    
    color = pow( color, vec3(1.0/2.2) );
    
    gl_FragColor = vec4(color, 1.0);
    
    //gl_FragColor = decodedNormal;
    //gl_FragColor = mix(d, decodedNormal, vTexCoords.x > 0.5 ? 1.0 : 0.0);
  }