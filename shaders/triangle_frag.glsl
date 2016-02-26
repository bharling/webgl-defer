precision mediump float;

varying vec2 vuv;
varying vec2 vpx;
uniform vec2 res;
uniform sampler2D tex;

void main (void) {
	vec4 col = texture2D(tex, vuv);

	bool border = (
		vpx.x <= 1.0 ||
		vpx.y <= 1.0 ||
		vpx.x >= res.x - 1.0 ||
		vpx.y >= res.y -1.0
	);

	gl_FragColor = !border ? mix(
		vec4(0.0, 0.0, 0.0, 1.0),
		vec4(col.rgb, 1.0),
		col.a
	) : vec4(1.0, 1.0, 1.0, 1.0);
}