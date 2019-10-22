gulp = require 'gulp'
sass = require 'gulp-sass'
connect = require 'gulp-connect'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
markdown = require 'gulp-markdown'
wrap = require 'gulp-wrap'
front_matter = require 'gulp-front-matter'
ext_replace = require 'gulp-ext-replace'

postcss = require 'gulp-postcss'
autoprefixer = require 'autoprefixer'
cssnano = require 'cssnano'

src   = './src/'
build = './build/'

templates = "#{src}templates/"
html_src  = "#{src}html/**/*.html"
sass_src  = "#{src}sass/**/*.scss"
asset_src = "#{src}assets/**/*"
md_src    = "#{src}md/**/*.md"
js        = "#{src}js/"

gulp.task 'server', ->
  connect.server
    root: build,
    livereload: true

gulp.task 'ie8_js', ->
  gulp.src "#{js}ie8/*.js"
    .pipe concat "ie8.js"
    .pipe gulp.dest("#{build}js")

gulp.task 'vendor_js', ->
  gulp.src "#{js}vendor/**/*.js"
    .pipe concat "vendor.js"
    .pipe uglify()
    .pipe gulp.dest("#{build}js")

gulp.task 'assets', ->
  gulp.src asset_src
    .pipe gulp.dest("#{build}")
    .pipe connect.reload()

gulp.task 'sass', ->
  gulp.src sass_src
    .pipe sass(
      style: 'compressed',
      includePaths: [
        './node_modules/normalize-scss/sass/']
      ).on('error', sass.logError)
    .pipe postcss [
      autoprefixer(),
      cssnano() ]
    .pipe gulp.dest("#{build}css")
    .pipe connect.reload()

gulp.task 'html', ->
  gulp.src html_src
    .pipe gulp.dest(build)
    .pipe connect.reload()

gulp.task 'md', ->
  gulp.src md_src
    .pipe front_matter(
      property: 'front',
      remove: true)
    .pipe markdown()
    .pipe wrap(src: "#{templates}layout.html")
    .pipe ext_replace('.html')
    .pipe gulp.dest(build)
    .pipe connect.reload()

gulp.task 'watch', ->
  gulp.watch asset_src, gulp.series ['assets']
  gulp.watch sass_src, gulp.series ['sass']
  gulp.watch html_src, gulp.series ['html']
  gulp.watch md_src, gulp.series ['md']
  gulp.watch "#{templates}**", gulp.series ['md']

gulp.task 'build', gulp.parallel ['ie8_js', 'vendor_js', 'assets', 'sass', 'html', 'md']
gulp.task 'default', gulp.series ['build', gulp.parallel ['server', 'watch'] ]

