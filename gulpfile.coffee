gulp = require 'gulp'
connect = require 'gulp-connect'
markdown = require 'gulp-markdown'
wrap = require 'gulp-wrap'
front_matter = require 'gulp-front-matter'
ext_replace = require 'gulp-ext-replace'
rename = require 'gulp-rename'
postcss = require 'gulp-postcss'
postcss_import = require 'postcss-import'
postcss_preset_env = require 'postcss-preset-env'
tailwindcss = require 'tailwindcss'
purgecss = require '@fullhuman/postcss-purgecss'
cssnano = require 'cssnano'
webpackStream = require 'webpack-stream'
webpack = require 'webpack'

src   = './src/'
build = './build/'
build_dev = './build_dev/'

templates = "#{src}templates/"
html_src  = "#{src}html/**/*.html"
css_src   = "#{src}css/**/*.css"
asset_src = "#{src}assets/**/*"
md_src    = "#{src}md/**/*.md"
js_src    = "#{src}js/**/*"

webpack_common =
  output:
    filename: 'app.js'
  module:
    rules: [
      test: /\.m?js$/
      exclude: /(node_modules|bower_components)/
      #exclude: /(node_modules\/(?!my-import)|bower_components)/
      use:
        loader: 'babel-loader'
        options:
          presets: ['@babel/preset-env'] ]

gulp.task 'js_dev', ->
  gulp.src "#{src}js/app.js"
    .pipe webpackStream {
      webpack_common...,
      mode: 'development',
      devtool: 'source-map'
    }, webpack
    .pipe gulp.dest "#{build_dev}js"
    .pipe connect.reload()

gulp.task 'js_prod', ->
  gulp.src "#{src}js/app.js"
    .pipe webpackStream {
      webpack_common...,
      mode: 'production'
    }, webpack
    .pipe gulp.dest "#{build}js"

gulp.task 'js', gulp.series ['js_dev', 'js_prod']

gulp.task 'css', ->
  gulp.src "#{src}css/*.css"
    .pipe postcss [
      postcss_import(),
      tailwindcss(),
      postcss_preset_env() ]
    .pipe gulp.dest "#{build_dev}css"
    .pipe connect.reload()
    .pipe postcss [
      purgecss
        content: ["#{templates}**/*.html", html_src]
      cssnano() ]
    .pipe gulp.dest "#{build}css"

# Rename foo.html -> foo/index.html
html_dir_index = (path) ->
  return if path.basename == 'index'
  path.dirname += "/#{path.basename}"
  path.basename = 'index'

gulp.task 'html', ->
  gulp.src html_src
    .pipe front_matter
      property: 'front',
      remove: true
    .pipe wrap(src: "#{templates}layout.html")
    .pipe rename html_dir_index
    .pipe gulp.dest build_dev
    .pipe connect.reload()
    .pipe gulp.dest build

gulp.task 'md', ->
  gulp.src md_src
    .pipe front_matter
      property: 'front',
      remove: true
    .pipe markdown()
    .pipe wrap(src: "#{templates}layout.html")
    .pipe ext_replace '.html'
    .pipe rename html_dir_index
    .pipe gulp.dest build_dev
    .pipe connect.reload()
    .pipe gulp.dest build

gulp.task 'assets', ->
  gulp.src asset_src
    .pipe gulp.dest build_dev
    .pipe connect.reload()
    .pipe gulp.dest build

gulp.task 'watch', (done) ->
  gulp.watch js_src, gulp.task 'js'
  gulp.watch [css_src, './tailwind.config.js'], gulp.task 'css'
  gulp.watch html_src, gulp.parallel ['html','css']
  gulp.watch md_src, gulp.task 'md'
  gulp.watch asset_src, gulp.task 'assets'
  gulp.watch "#{templates}**", gulp.parallel ['html','md','css']
  done()

gulp.task 'server', (done) ->
  connect.server
    root: build_dev,
    livereload: true
  done()

gulp.task 'build', gulp.parallel ['js', 'assets', 'css', 'html', 'md']
gulp.task 'default', gulp.series ['build', gulp.parallel ['server', 'watch'] ]

