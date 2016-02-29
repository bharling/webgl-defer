tCache = null
debug_textures = []
shader = null

triangle = () ->
	vao = tCache
	if !vao?
		verts = new Float32Array([-1, -1, -1, 4, 4, -1])
		buf = new DFIR.Buffer(verts, 2, gl.STATIC_DRAW)
		tCache = vao = buf
		vao = buf

	vao.bind()
	gl.drawArrays(gl.TRIANGLES, 0, 3)
	vao.release()


texturedebug = (textures) ->
	width = gl.drawingBufferWidth
	height = gl.drawingBufferHeight

	if not shader?
		DFIR.ShaderLoader.load 'shaders/triangle_vert.glsl', 'shaders/triangle_frag.glsl', (program) ->
			shader = new DFIR.Shader( program )

	gl.bindFramebuffer gl.FRAMEBUFFER, null
	gl.disable gl.DEPTH_TEST
	gl.disable gl.CULL_FACE
	gl.disable gl.BLEND

	padding = 10
	localWidth = width * 0.15
	localHeight = localWidth * (height/width)
	startX = width - localWidth - padding
	startY = height - localHeight - padding

	if shader?
		shader.use()
		gl.uniform2fv(shader.getUniform('res'), [localWidth, localHeight])

		for i in [0...textures.length]
			x = startX
			y = startY - localHeight * i - padding * i

			gl.viewport(x, y, localWidth, localHeight)
			gl.activeTexture(gl.TEXTURE0)
			gl.bindTexture(gl.TEXTURE_2D, textures[i])

			gl.uniform1i(shader.getUniform('tex'), 0)

			triangle()

exports = if typeof exports isnt 'undefined' then exports else window
exports.texturedebug = texturedebug
