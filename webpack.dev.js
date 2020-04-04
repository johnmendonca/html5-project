const webpack_common = require('./webpack.common.js')

module.exports = {
  ...webpack_common,
  mode: 'development',
  devtool: 'source-map'
}

