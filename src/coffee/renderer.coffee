class DFIR.Renderer

	draw : (scene, camera) ->
		viewMatrix = camera.getViewMatrix()
		projectionMatrix = camera.getProjectionMatrix()

		for material in scene.materials:
			material.use()
			for obj in material.objects:
				obj.draw()

			material.stopUsing()