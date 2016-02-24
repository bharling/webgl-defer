class DFIR.Light
	constructor: (@position, @color, @strength=1.0, @attenuation=1.0) ->
		@color ?= vec3.fromValues 1.0, 1.0, 1.0


class DFIR.DirectionalLight extends DFIR.Light
