

class DFIR.Transform
	constructor: () ->
		@_translation = vec3.create()
		@_scale = vec3.fromValues 1.0, 1.0, 1.0
		@_rotation = quat.create()

	translate: (vec) ->
		vec3.add @_translation, @_translation, vec

	scale: (num) ->
		vec3.scale @_scale, @_scale, num

	scaleVector: (vec) ->
		vec3.multiply @_scale, @_scale, vec

	rotateX: (rad) ->
		quat.rotateX @_rotation, @_rotation, rad

	rotateY: (rad) ->
		quat.rotateY @_rotation, @_rotation, rad

	rotateZ: (rad) ->
		quat.rotateZ @_rotation, @_rotation, rad


	getMatrix: (dst) ->
		dst ?= mat4.create()
		mat4.fromRotationTranslationScale dst,@_rotation, @_translation, @_scale



class DFIR.SceneNode
	constructor: (@transform, @object=null) ->
		@localMatrix = mat4.create()
		@worldMatrix = mat4.create()
		@children = []
		@parent = null
		@visible = true
		@transform ?= new DFIR.Transform()

	# we shortbut to the internal transform class
	translate: (vec) ->
		@transform.translate vec

	scale: (num) ->
		@transform.scale num

	scaleVector: (vec) ->
		@transform.scaleVector vec

	rotateX: (rad) ->
		@transform.rotateX rad

	rotateY: (rad) ->
		@transform.rotateY rad

	rotateZ: (rad) ->
		@transform.rotateZ rad

	# walk this node and all children
	# calling callback on all visible
	walk: (callback) ->
		if @visible
			callback this
			for child in @children
				child.walk(callback)

			
			


	addChild: (child) ->
		child.setParent this

	setParent: (parent) ->
		if not parent?
			return
		if @parent and this in @parent.children
			@parent.children = @parent.chilren.filter (child) -> child isnt this
		if parent.children?
			parent.children.push @
		@parent = parent

	updateWorldMatrix: (parentMatrix) ->
		mat4.copy @localMatrix, @transform.getMatrix()
		if parentMatrix
			mat4.multiply @worldMatrix, parentMatrix, @localMatrix
		else
			mat4.copy @worldMatrix, @localMatrix 

		for child in @children
			child.updateWorldMatrix @worldMatrix


	attach: (@object) ->



class DFIR.Scene
	constructor:() ->
		@root = new DFIR.SceneNode()


	