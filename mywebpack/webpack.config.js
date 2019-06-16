var path = require('path');

module.exports = {
  mode: 'development', // 'production', 'development', 'none'
  entry: './src/index.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
    publicPath: '/dist'
  },
  module: {
    rules : [{
      test: /\.js$/,
      include: path.resolve(__dirname, 'src'),
      use: {
        loader: 'babel-loader',
        options: {
          presets : [
            ['@babel/env', {
              'targets': {
                // "android": "67",
                // "chrome": "73",
                // "edge": "17",
                // "firefox": "65",
                // "ie": "10",
                // "ios": "12",
                // "opera": "12.1",
                // "safari": "12",
                // "samsung": "8.2",
                'browsers': ['last 2 versions']
              },
              debug: true
            }]
          ]
        }
      }
    }]
  }
}