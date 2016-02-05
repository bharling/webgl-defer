class DFIR.Renderer
	constructor: (canvas) ->
		@ready = false
		@width = if canvas then canvas.width else 1280
		@height = if canvas then canvas.height else 720
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


	enableGBuffer: (scene, camera) ->
		@gbuffer.bind()
		gl.cullFace ( gl.BACK ) 
		gl.blendFunc( gl.ONE, gl.ZERO )
		gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )
		gl.enable(gl.CULL_FACE)
		

	draw : (scene, camera) ->
		if @ready
			viewMatrix = camera.getViewMatrix()
			projectionMatrix = camera.getProjectionMatrix()

			for material in scene.materials
				material.use()
				for obj in material.objects
					obj.draw()

				material.stopUsing()
