const purgecss = require("@fullhuman/postcss-purgecss")({
  content: ["./src/**/*.html"],
  defaultExtractor: content => content.match(/[\w-/.:]+(?<!:)/g) || []
});

module.exports = (ctx) => {
  return {
    plugins: [
      require("postcss-import"),
      require("tailwindcss"),
      require("postcss-preset-env")({
        stage: 1,
        // need this for compatability with @tailwindcss/ui
        features: {
          'focus-within-pseudo-class': false
        }
      }),
      ...(process.env.NODE_ENV === "production" || ctx.options.env === 'production'
        ? [purgecss, require('cssnano')]
        : [])
    ]
  }
}
