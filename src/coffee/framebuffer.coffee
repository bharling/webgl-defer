initTexture = (width, height, format, attachment) ->


class DFIR.FrameBuffer
	constructor: (@width, @height, @colorTargets=1, @depthTarget=true) ->
		@textures = []
		@init()

	check: ->
		@ext = window.WEBGL_draw_buffers = gl.getExtension('WEBGL_draw_buffers')
		if not @ext?
			alert 'Draw Buffers unsupported'

	init: ->
		@fb = gl.createFramebuffer()
		gl.bindFramebuffer(gl.FRAMEBUFFER, @fb)

		for i in [0 ... @colorTargets]
			@textures[i] = initTexture(@width, @height, gl.RGB4, gl.COLOR_ATTACHMENT0 + i)

		




	bind: ->




