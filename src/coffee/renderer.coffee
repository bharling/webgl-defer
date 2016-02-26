class DFIR.Renderer
	constructor: (canvas, @post_process_enabled=false) ->
		@ready = false
		@debug_view = 0
		@width = if canvas then canvas.width else window.innerWidth
		@height = if canvas then canvas.height else window.innerHeight
		@exposure = 1.0
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
		@drawCallCount = 0


	checkReadiness: ->
		if @quad? and @outputQuad?
			@ready=true

	createTargets: () ->
		@accumulationTexture = @gbuffer.createTexture()
		@frameBuffer = gl.createFramebuffer()
		gl.bindFramebuffer gl.FRAMEBUFFER, @frameBuffer
		gl.bindTexture gl.TEXTURE_2D, @accumulationTexture
		gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, @accumulationTexture, 0
		status = gl.checkFramebufferStatus gl.FRAMEBUFFER
		console.log "Final FrameBuffer status after initialization: #{status}";
		gl.bindFramebuffer gl.FRAMEBUFFER, null
		gl.bindTexture gl.TEXTURE_2D, null


		DFIR.ShaderLoader.load 'shaders/fs_quad_vert.glsl', 'shaders/fs_quad_frag.glsl', (program) =>
			@quad = new DFIR.FullscreenQuad()
			@quad.setMaterial ( new DFIR.Shader ( program ))
			@quad.material.showInfo()
			@checkReadiness()

		DFIR.ShaderLoader.load 'shaders/fs_quad_vert.glsl', 'shaders/post_process_frag.glsl', (program) =>
			@outputQuad = new DFIR.FullscreenQuad()
			@outputQuad.setMaterial( new DFIR.Shader (program))
			@checkReadiness()



	setDefaults: () ->
		gl.clearColor 0.0, 0.0, 0.0, 1.0
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
		gl.enable gl.BLEND
		gl.blendFunc( gl.ONE, gl.ZERO )
		gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )
		gl.enable(gl.CULL_FACE)


	updateGBuffer: (scene, camera) ->
		# render our gBuffer first
		@enableGBuffer()

		camera.updateViewMatrix()
		camera.updateProjectionMatrix()
		scene.root.updateWorldMatrix()


		dc = 0
		scene.root.walk (node) ->
			if node.object?
				if node.object.bind()
					#gl.uniform1f(node.object.material.getUniform('metallic'), @metallic)
					#gl.uniform1f(node.object.material.getUniform('roughness'), @roughness);
					node.object.draw camera, node.worldMatrix
					node.object.release()
					dc++

		@drawCallCount = dc

		@gbuffer.release()


	doLighting: (scene, camera) ->

		if @post_process_enabled
			gl.bindFramebuffer gl.FRAMEBUFFER, @frameBuffer
			gl.clearColor 0.0, 0.0, 0.0, 1.0
			gl.clear gl.COLOR_BUFFER_BIT
			#gl.bindFramebuffer gl.FRAMEBUFFER, null
			#return

		@quad.material.use()
		@quad.bind()



		gl.enable gl.BLEND
		gl.blendFunc gl.ONE, gl.ONE

		gl.activeTexture(gl.TEXTURE0)
		gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getDepthTextureUnit())

		gl.activeTexture(gl.TEXTURE1)
		gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getNormalsTextureUnit())

		gl.activeTexture(gl.TEXTURE2)
		gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getAlbedoTextureUnit())

		gl.uniform1i(@quad.material.getUniform('depthTexture'), 0)
		gl.uniform1i(@quad.material.getUniform('normalsTexture'), 1)
		gl.uniform1i(@quad.material.getUniform('albedoTexture'), 2)
		gl.uniformMatrix4fv(@quad.material.getUniform('uViewMatrix'), false, camera.getViewMatrix())
		gl.uniformMatrix4fv(@quad.material.getUniform('uViewProjectionMatrix'), false, camera.getViewProjectionMatrix())
		gl.uniformMatrix4fv(@quad.material.getUniform('inverseProjectionMatrix'), false, camera.getInverseProjectionMatrix())
		gl.uniformMatrix4fv(@quad.material.getUniform('inverseViewProjectionMatrix'), false, camera.getInverseViewProjectionMatrix())
		gl.uniform1i(@quad.material.getUniform('DEBUG'), @debug_view)
		gl.uniform1f(@quad.material.getUniform('exposure'), @exposure)

		# draw directional lights

		for light in scene.directionalLights
			gl.uniform3fv(@quad.material.getUniform('lightDirection'), light.position)
			gl.uniform3fv(@quad.material.getUniform('lightColor'), light.color)
			gl.uniform1f(@quad.material.getUniform('lightStrength'), light.strength)
			gl.uniform1f(@quad.material.getUniform('lightAttenuation'), light.attenuation)
			gl.drawArrays(gl.TRIANGLES, 0, @quad.vertexBuffer.numItems)

		@quad.release()




		if @post_process_enabled
			gl.bindFramebuffer gl.FRAMEBUFFER, null

	doPostProcess: (scene, camera) ->
		@setDefaults()

		@outputQuad.material.use()
		@outputQuad.bind()

		#gl.activeTexture(gl.TEXTURE0)
		#gl.bindTexture(gl.TEXTURE_2D, @gbuffer.getDepthTextureUnit())

		gl.activeTexture(gl.TEXTURE0)
		gl.bindTexture(gl.TEXTURE_2D, @accumulationTexture)

		#gl.uniform1i(@outputQuad.material.getUniform('depthTexture'), 0)
		gl.uniform1i(@outputQuad.material.getUniform('renderTexture'), 0)

		gl.uniform1i(@outputQuad.material.getUniform('DEBUG'), @debug_view)
		gl.uniform1f(@outputQuad.material.getUniform('exposure'), @exposure)

		gl.drawArrays(gl.TRIANGLES, 0, @quad.vertexBuffer.numItems)

		@outputQuad.release()

	reset: () ->
		gl.viewport 0, 0, @width, @height
		gl.enable gl.DEPTH_TEST
		gl.enable gl.CULL_FACE

	draw : (scene, camera) ->
		if @ready
			@reset()
			@updateGBuffer(scene, camera)
			@doLighting(scene, camera)
			if @post_process_enabled
				@doPostProcess(scene, camera)
