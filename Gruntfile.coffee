module.exports = (grunt) ->
  
  coffeeFiles = [ 'src/coffee/intro.coffee', 'src/coffee/buffer.coffee' , 'src/coffee/object.coffee', 'src/coffee/json_model.coffee' , 'src/coffee/shader.coffee', 'src/coffee/Gbuffer.coffee' ]
  
  
  
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
      
      coffee:
        files: [ 'src/**/*.coffee' ]
        tasks: ['coffee:develop']
        options:
          spawn: false
        
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-newer'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    
    grunt.registerTask 'default', ['coffee:develop']
