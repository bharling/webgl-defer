	attribute vec3 aVertexPosition;
	attribute vec2 aVertexTextureCoords;
	
	varying vec2 vTexCoords;
	varying float debug;
	
	void main (void) {
		gl_Position = vec4(aVertexPosition.xy, 0.0, 1.0);
		debug = aVertexPosition.z;
		vTexCoords = aVertexTextureCoords;
	}