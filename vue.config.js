module.exports = {
  pluginOptions: {
    electronBuilder: {
      chainWebpackRendererProcess: config => {
        config.plugin('define').tap(args => {
          args[0]['IS_ELECTRON'] = true
          return args
        })
      },
    },
  },
  chainWebpack: config => {
    config.module
      .rule('webpack-conditional-loader')
      .test(/\.js$/)
      .use('webpack-conditional-loader')
      .loader('webpack-conditional-loader')
      .end()
  },
}
