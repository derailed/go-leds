gulp      = require 'gulp'

coffee    = require 'gulp-coffee'
concat    = require 'gulp-concat'
connect   = require 'gulp-connect'
importCss = require 'gulp-cssimport'
include   = require 'gulp-include'
inject    = require 'gulp-inject'
jade      = require 'gulp-jade'
plumber   = require 'gulp-plumber'
sass      = require 'gulp-ruby-sass'
templates = require 'gulp-angular-templatecache'
haml      = require "gulp-haml"

src =
  coffee: 'app/scripts/*.coffee'
  html:   'app/views/index.html'
  jade:   'app/views/*.jade'
  sass:   'app/styles/main.sass'
  haml:   'app/view/*.haml'

compiledVendor = false

gulp.task 'connect', ->
  connect.server
    root:       ['dist'],
    port:       8000,
    livereload: true

gulp.task 'html', ['coffee', 'vendor', 'jade', 'haml'], ->
  gulp.src(src.html)
      .pipe(plumber())
      .pipe(inject(gulp.src('./js/vendor*.js', {read: false, cwd: __dirname + '/dist/'}), {starttag: '<!-- inject:vendor:js -->'}))
      .pipe(inject(gulp.src('./js/app*.js', {read: false, cwd: __dirname + '/dist/'}), {starttag: '<!-- inject:app:js -->'}))
      .pipe(inject(gulp.src('./js/templates*.js', {read: false, cwd: __dirname + '/dist/'}), {starttag: '<!-- inject:templates:js -->'}))
      .pipe(gulp.dest('dist'))
      .pipe(connect.reload())

gulp.task 'fonts', ->
    gulp.src( ['./bower_components/font-awesome/fonts/fontawesome-webfont.*'] )
        .pipe(gulp.dest('dist/fonts/'))

gulp.task 'coffee', ->
  gulp.src(src.coffee)
      .pipe(plumber())
      .pipe(include(extensions: ["js", "coffee"]))
      .pipe(coffee())
      .pipe(concat('app.js'))
      .pipe(gulp.dest('dist/js'))
      .pipe(connect.reload())

gulp.task 'vendor', ->
  if ! compiledVendor
    compiledVendor = true

    json = require('fs').readFileSync('app/scripts/vendor.json')
    vendor = JSON.parse(json)

    gulp.src(vendor)
        .pipe(plumber())
        .pipe(concat('vendor.js'))
        .pipe(gulp.dest('dist/js'))
        .pipe(connect.reload())

gulp.task 'jade', ->
  gulp.src(src.jade)
      .pipe(plumber())
      .pipe(jade())
      .pipe(templates(standalone: true, root: '/'))
      .pipe(gulp.dest('dist/js'))
      .pipe(connect.reload())

gulp.task 'haml', ->
  gulp.src(src.haml)
      .pipe(plumber())
      .pipe(haml())
      .pipe(templates(standalone: true, root: '/'))
      .pipe(gulp.dest('dist/js'))
      .pipe(connect.reload())

gulp.task 'sass', ->
  gulp.src(src.sass)
      .pipe(plumber())
      .pipe(sass())
      .pipe(importCss())
      .pipe(concat('style.css'))
      .pipe(gulp.dest('dist/css'))
      .pipe(connect.reload())

gulp.task 'watch', ->
  gulp.watch(src.coffee, ['coffee'])
  gulp.watch(src.html,   ['html'])
  gulp.watch(src.jade,   ['jade'])
  gulp.watch(src.sass,   ['sass'])

gulp.task 'default', ['connect', 'coffee', 'html', 'jade', 'sass', 'fonts', 'watch']
