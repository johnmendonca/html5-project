gulp = require 'gulp'
connect = require 'gulp-connect'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
markdown = require 'gulp-markdown'
wrap = require 'gulp-wrap'
front_matter = require 'gulp-front-matter'
ext_replace = require 'gulp-ext-replace'
postcss = require 'gulp-postcss'
postcss_import = require 'postcss-import'
postcss_preset_env = require 'postcss-preset-env'
tailwindcss = require 'tailwindcss'
purgecss = require '@fullhuman/postcss-purgecss'
cssnano = require 'cssnano'
bro = require 'gulp-bro'
babelify = require 'babelify'

src   = './src/'
build = './build/'

templates = "#{src}templates/"
html_src  = "#{src}html/**/*.html"
css_src   = "#{src}css/**/*.css"
asset_src = "#{src}assets/**/*"
md_src    = "#{src}md/**/*.md"
js_src    = "#{src}js/**/*.js"
es6_src   = "#{src}es6/**/*.js"

gulp.task 'server', ->
  connect.server
    root: build,
    livereload: true

gulp.task 'js', ->
  gulp.src js_src
    .pipe concat "vendor.js"
    .pipe uglify()
    .pipe gulp.dest "#{build}js"

gulp.task 'es6', ->
  gulp.src "#{src}es6/app.js"
    .pipe bro transform: [
      babelify.configure presets: ['@babel/preset-env'] ]
    .pipe uglify()
    .pipe gulp.dest "#{build}js"

gulp.task 'assets', ->
  gulp.src asset_src
    .pipe gulp.dest build
    .pipe connect.reload()

gulp.task 'css', ->
  gulp.src "#{src}css/*.css"
    .pipe postcss [
      postcss_import(),
      tailwindcss(),
      postcss_preset_env(),
      purgecss(content: ["#{templates}**/*.html", html_src]),
      cssnano() ]
    .pipe gulp.dest "#{build}css"
    .pipe connect.reload()

gulp.task 'html', ->
  gulp.src html_src
    .pipe front_matter
      property: 'front',
      remove: true
    .pipe wrap(src: "#{templates}layout.html")
    .pipe gulp.dest build
    .pipe connect.reload()

gulp.task 'md', ->
  gulp.src md_src
    .pipe front_matter
      property: 'front',
      remove: true
    .pipe markdown()
    .pipe wrap(src: "#{templates}layout.html")
    .pipe ext_replace '.html'
    .pipe gulp.dest build
    .pipe connect.reload()

gulp.task 'watch', ->
  gulp.watch asset_src, gulp.series ['assets']
  gulp.watch css_src, gulp.series ['css']
  gulp.watch html_src, gulp.parallel ['html','css']
  gulp.watch md_src, gulp.series ['md']
  gulp.watch js_src, gulp.series ['js']
  gulp.watch es6_src, gulp.series ['es6']
  gulp.watch "#{templates}**", gulp.parallel ['html','md','css']

gulp.task 'build', gulp.parallel ['es6', 'js', 'assets', 'css', 'html', 'md']
gulp.task 'default', gulp.series ['build', gulp.parallel ['server', 'watch'] ]

