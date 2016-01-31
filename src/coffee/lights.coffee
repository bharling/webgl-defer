class DFIR.DirectionalLight extends DFIR.Object3D

	bind : (uniforms) ->
		gl.uniform3fv(uniforms.lightColor, @color)
		gl.uniform3fv(uniforms.lightDirection, @direction)

