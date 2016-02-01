module.exports = (grunt) ->

  coffeeFiles = [

    'src/coffee/intro.coffee',
    'src/coffee/math.coffee',
    'src/coffee/buffer.coffee' ,
    'src/coffee/object.coffee',
    'src/coffee/geometry.coffee',
    'src/coffee/json_model.coffee' ,
    'src/coffee/shader.coffee',
    'src/coffee/camera.coffee',

    'src/coffee/lights.coffee',
    'src/coffee/shadows.coffee',
    'src/coffee/Gbuffer.coffee',
    'src/coffee/fullscreenQuad.coffee',
    'src/coffee/debug_view.coffee']



  grunt.initConfig
    coffee:
      develop:
        options:
          join:true
        files: 'js/main.js' : coffeeFiles

    watch:
      options:
        livereload: true

      markup:
        files: ['index.html']
        tasks: []

      shaders:
        files: ['shaders/*.glsl']
        tasks: []

      coffee:
        files: [ 'src/**/*.coffee' ]
        tasks: ['coffee:develop']
        options:
          spawn: false

    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-newer'
    grunt.loadNpmTasks 'grunt-contrib-watch'

    grunt.registerTask 'default', ['coffee:develop']
