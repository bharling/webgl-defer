class DFIR.Renderer
	constructor: (canvas) ->
		@width = if canvas then canvas.width else 1280
		@height = if canvas then canvas.height else 720
		if !canvas?
			canvas = document.createElement 'canvas'
			document.body.appendChild canvas

		canvas.width = @width
		canvas.height = @height
		window.gl = canvas.getContext("webgl")
		gl.viewportWidth = canvas.width
		gl.viewportHeight = canvas.height
		@canvas = canvas
		@setDefaults()


	setDefaults: () ->
		gl.clearColor 0.0, 0.0, 0.0, 0.0
		gl.enable gl.DEPTH_TEST
		gl.depthFunc gl.LEQUAL
		gl.depthMask true
		gl.clearDepth 1.0
		gl.enable gl.BLEND
		gl.blendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA
		gl.enable gl.CULL_FACE

	draw : (scene, camera) ->
		viewMatrix = camera.getViewMatrix()
		projectionMatrix = camera.getProjectionMatrix()

		for material in scene.materials:
			material.use()
			for obj in material.objects:
				obj.draw()

			material.stopUsing()
