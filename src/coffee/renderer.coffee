class DFIR.Renderer
	constructor: (canvas) ->
		@ready = false
		@debug_view = 0
		@width = if canvas then canvas.width else 1280
		@height = if canvas then canvas.height else 720
		@sunPosition = vec3.fromValues 30.0, 60.0, -20.0
		if !canvas?
			canvas = document.createElement 'canvas'
			document.body.appendChild canvas

		canvas.width = @width
		canvas.height = @height
		DFIR.gl = window.gl = canvas.getContext("webgl")
		gl.viewportWidth = canvas.width
		gl.viewportHeight = canvas.height
		@canvas = canvas
		@gbuffer = new DFIR.Gbuffer(1.0)
		@createTargets()
		@setDefaults()



	createTargets: () ->
		DFIR.ShaderLoader.load 'shaders/fs_quad_vert.glsl', 'shaders/fs_quad_frag.glsl', (program) =>
			@quad = new DFIR.FullscreenQuad()
			@quad.setMaterial ( new DFIR.Shader ( program ))
			@quad.material.showInfo()
			@ready = true


	setDefaults: () ->
		gl.clearColor 0.0, 0.0, 0.0, 0.0
		gl.enable gl.DEPTH_TEST
		gl.depthFunc gl.LEQUAL
		gl.depthMask true
		gl.clearDepth 1.0
		gl.enable gl.BLEND
		gl.blendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA
		gl.enable gl.CULL_FACE


	enableGBuffer: () ->
		@gbuffer.bind()
		gl.cullFace ( gl.BACK ) 
		gl.blendFunc( gl.ONE, gl.ZERO )
		gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )
		gl.enable(gl.CULL_FACE)


	updateGBuffer: (scene, camera) ->
		# render our gBuffer first
		@enableGBuffer()

		camera.updateViewMatrix()
		camera.updateProjectionMatrix()
		scene.root.updateWorldMatrix()

		scene.root.walk (node) ->
			if node.object?
				if node.object.bind()
					node.object.draw camera, node.worldMatrix
					node.object.release()

		@gbuffer.release()


	doLighting: (scene, camera) ->
		@quad.material.use()
		@quad.bind()

		gl.activeTexture(gl.TEXTURE0)
		gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getDepthTextureUnit())

		gl.activeTexture(gl.TEXTURE1)
		gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getNormalsTextureUnit())

		gl.activeTexture(gl.TEXTURE2)
		gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getAlbedoTextureUnit())

		gl.uniform1i(@quad.material.getUniform('depthTexture'), 0)
		gl.uniform1i(@quad.material.getUniform('normalsTexture'), 1)
		gl.uniform1i(@quad.material.getUniform('albedoTexture'), 2)

		gl.uniform3fv(@quad.material.getUniform('lightPosition'), @sunPosition)

		#console.log(sunLight.position)

		#sunLight.bind(@quad.material.uniforms)

		gl.uniformMatrix4fv(@quad.material.getUniform('inverseProjectionMatrix'), false, camera.getInverseProjectionMatrix())

		#gl.uniform4f(@quad.material.getUniform('projectionParams'), projectionParams[0], projectionParams[1], projectionParams[2], projectionParams[3] )

		gl.uniform1i(@quad.material.getUniform('DEBUG'), @debug_view)

		gl.drawArrays(gl.TRIANGLES, 0, @quad.vertexBuffer.numItems)

		@quad.release()

	draw : (scene, camera) ->
		if @ready
			@updateGBuffer(scene, camera)
			@doLighting(scene, camera)

