// Karma configuration
// Generated on Mon Jun 03 2019 23:19:22 GMT+0900 (대한민국 표준시)
const path = require('path');

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '',


    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['jasmine'],

    // 여기부터 기본 init에서 수정 사항
    // 웹팩 설정 가져오기?? 아까 설치한 모듈('karma-webpack')
    webpack: {
      mode: 'development',
      module: {
        rules: [
          {
            test: /\.jsx$/i,
            include: [
              path.resolve(__dirname, 'src')
            ],
            exclude: [/node_modules/],
            use: {
              loader: 'babel-loader',
              options: {
                presets: ['@babel/preset-env'],
               // plugins: ['@babel/plugin-proposal-class-properties']
              }
            }
          },
          {
            test: /\.tsx$/i,
            include: [
              path.resolve(__dirname, 'src')
            ],
            exclude: [/node_modules/],
            use: {
              loader: 'ts-loader'
            }
          },
          {
            test: /\.css$/i,
            use: ['style-loader','css-loader'],
          }
        ]
      }
  },


    // list of files / patterns to load in the browser
    files: [
      '**/*.spec.js',
      // 'src/**/*.spec.ts',
      // 'test/**/*.spec.js',
      // 'test/**/*.spec.ts'
    ],


    // list of files / patterns to exclude
    exclude: [
      
    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      'src/**/*.spec.js': ['webpack'], // test/*spec.js을 실행하기 전에 'webpack'을 선행
      'src/**/*.spec.ts': ['webpack'],
    },


    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['mocha','kjhtml'/*,'mocha','dots','progress','spec'*/],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['Chrome'],


    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false,

    // Concurrency level
    // how many browser should be started simultaneous
    concurrency: Infinity
  })
}
