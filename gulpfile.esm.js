import { series, parallel, src, dest, watch } from 'gulp'
import connect            from 'gulp-connect'
import markdown           from 'gulp-markdown'
import wrap               from 'gulp-wrap'
import front_matter       from 'gulp-front-matter'
import ext_replace        from 'gulp-ext-replace'
import rename             from 'gulp-rename'
import postcss            from 'gulp-postcss'
import postcss_import     from 'postcss-import'
import postcss_preset_env from 'postcss-preset-env'
import tailwindcss        from 'tailwindcss'
import purgecss           from '@fullhuman/postcss-purgecss'
import cssnano            from 'cssnano'
import webpackStream      from 'webpack-stream'
import webpack            from 'webpack'

const src_root  = './src/'
const dest_prod = './build/'
const dest_dev  = './build_dev/'

const templates = `${src_root}templates/`
const html_src  = `${src_root}html/**/*.html`
const css_src   = `${src_root}css/**/*.css`
const asset_src = `${src_root}assets/**/*`
const md_src    = `${src_root}md/**/*.md`
const js_src    = `${src_root}js/**/*`

const js_dev = () =>
  src(`${src_root}js/app.js`)
    .pipe(webpackStream(require('./webpack.dev.js'), webpack))
    .pipe(dest(`${dest_dev}js`))
    .pipe(connect.reload())

const js_prod = () =>
  src(`${src_root}js/app.js`)
    .pipe(webpackStream(require('./webpack.prod.js'), webpack))
    .pipe(dest(`${dest_prod}js`))

export const js = series(js_dev, js_prod)

export const css = () =>
  src(`${src_root}css/*.css`)
    .pipe(postcss([
      postcss_import(),
      tailwindcss(),
      postcss_preset_env()
    ]))
    .pipe(dest(`${dest_dev}css`))
    .pipe(connect.reload())
    .pipe(postcss([
      purgecss({
        content: [`${templates}**/*.html`, html_src]
      }),
      cssnano()
    ]))
    .pipe(dest(`${dest_prod}css`))

// Rename foo.html -> foo/index.html
const html_dir_index = (path) => {
  if (path.basename === 'index') {
    return
  }
  path.dirname += `/${path.basename}`
  path.basename = 'index'
}

export const html = () =>
  src(html_src)
    .pipe(front_matter({
      property: 'front',
      remove: true
    }))
    .pipe(wrap({
      src: `${templates}layout.html`
    }))
    .pipe(rename(html_dir_index))
    .pipe(dest(dest_dev))
    .pipe(connect.reload())
    .pipe(dest(dest_prod))

export const md = () =>
  src(md_src)
    .pipe(front_matter({
      property: 'front',
      remove: true
    }))
    .pipe(markdown())
    .pipe(wrap({
      src: `${templates}layout.html`
    }))
    .pipe(ext_replace('.html'))
    .pipe(rename(html_dir_index))
    .pipe(dest(dest_dev))
    .pipe(connect.reload())
    .pipe(dest(dest_prod))

export const assets = () =>
  src(asset_src)
    .pipe(dest(dest_dev))
    .pipe(connect.reload())
    .pipe(dest(dest_prod))

const watch_all = (done) => {
  watch(js_src, js)
  watch([css_src, './tailwind.config.js'], css)
  watch(html_src, parallel(html, css))
  watch(md_src, md)
  watch(asset_src, assets)
  watch(`${templates}**`, parallel(html, md, css))
  done()
}

const server = (done) => {
  connect.server({
    root: dest_dev,
    livereload: true
  })
  done()
}

export const build = parallel(js, css, assets, html, md)
export default series(build, parallel(server, watch_all))
