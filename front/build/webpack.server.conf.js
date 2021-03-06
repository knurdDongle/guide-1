const path = require('path')

const webpack = require('webpack')
const merge = require('webpack-merge')
const nodeExternals = require('webpack-node-externals')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const VueServerPlugin = require('vue-server-renderer/server-plugin')

const { distPath, env } = require('./build-config')
const { cssLoader, stylusLoader } = require('./style-loader.conf')
const baseConfig = require('./webpack.base.conf')

const webpackConfig = merge(baseConfig, {
  mode: process.env.NODE_ENV,

  target: 'node',

  entry: rootResolve('./client/entry.server.ts'),
  
  output: {
    path: distPath,
    filename: 'server-build.js',
    libraryTarget: 'commonjs2'
  },

  externals: nodeExternals({
    whitelist: [
      /\.css$/,
      /\.vue$/,
      /babel-polyfill/
    ]
  }),

  module: {
    rules: [
      cssLoader, stylusLoader
    ]
  },

  plugins: [
    new VueServerPlugin(),

    new webpack.DefinePlugin(Object.assign({}, env, {
      'process.env.VUE_ENV': JSON.stringify('server')
    }))
  ]
})

switch (process.env.NODE_ENV) {
  case 'production':
    webpackConfig.plugins.push(
      new MiniCssExtractPlugin({
        filename: 'static/css/[name].[contenthash].css',
        chunkFilename: 'static/css/[id].[contenthash].css'
      })
    )
    webpackConfig.optimization.splitChunks = false
    break
}

module.exports = webpackConfig

function rootResolve (filePath) {
  return path.resolve(__dirname, '../', filePath)
}
