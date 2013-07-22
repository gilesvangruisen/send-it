module.exports = (grunt) ->

    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'

        watch:
            coffee:
                files: [
                    '**/coffee/*.coffee'
                ]
                tasks: ['coffee']

        coffee:
            all:
                expand: true
                cwd: 'coffee'
                src: '**/*.coffee'
                dest: ''
                ext: '.js'

    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-coffee'

    grunt.registerTask 'default', ['coffee']
