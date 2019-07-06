// 수정하면 무슨 에러가 많이 나온다. ㅠ.ㅠ
// 해결 못 한 문제..
// test디렉토리 밑의 *.ts에서는 테스트 코드를 작성할 수 없다. 무슨 문제인지 모르겠다.
// Karma configuration
// Generated on Mon Jun 03 2019 23:19:22 GMT+0900 (대한민국 표준시)
const path = require('path');
var webpackConfig = require('./webpack.config')

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '',


    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['jasmine'],

    // list of files / patterns to load in the browser
    files: [
      {pattern: 'src/**/*.spec.js', watched:true, served:true, included: true},
      {pattern: 'src/**/*.spec.ts', watched:true, served:true, included: true},
      {pattern: 'test/**/*.js', watched:true, served:true, included: true},
      {pattern: 'test/**/*.ts', watched:true, served:true, included: true}
      /*parameters:
          watched: if autoWatch is true all files that have watched set to true will be watched for changes
          served: should the files be served by Karma's webserver?
          included: should the files be included in the browser using <script> tag?
          nocache: should the files be served from disk on each request by Karma's webserver? */
      /*assets:
          {pattern: '*.html', watched:true, served:true, included:false}
          {pattern: 'images/*', watched:false, served:true, included:false} */    
    ],

    // list of files / patterns to exclude
    exclude: [ ],

    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['Chrome'],

    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,

    client: {
      //capture all console output and pipe it to the terminal, true is default
      captureConsole:false,
      //if true, Karma clears the context window upon the completion of running the tests, true is default
      clearContext:false,
      //run the tests on the same window as the client, without using iframe or a new window, false is default
      runInParent: false,
      //true: runs the tests inside an iFrame; false: runs the tests in a new window, true is default
      useIframe:true,
      jasmine:{
        //tells jasmine to run specs in semi random order, false is default
        random: false
      }
    },
    // 여기부터 기본 init에서 수정 사항
    // 웹팩 설정 가져오기?? 아까 설치한 모듈('karma-webpack')
    webpack: {
      mode: 'development',
      //module: webpackConfig.module,
      resolve: webpackConfig.resolve,
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
            test: /\.tsx?$/i,
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

    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      'src/**/*.js': ['webpack'], // test/*spec.js을 실행하기 전에 'webpack'을 선행
      'src/**/*.ts': ['webpack'],
      'src/**/*.ts': ['webpack'],
    },

    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['kjhtml','mocha'/*,'mocha','dots','progress','spec'*/],

    mochaReporter: {
      output: 'noFailures' // full, autowatch, minimal
    },

    // web server port
    port: 9876,

    // enable / disable colors in the output (reporters and logs)
    colors: true,

    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false,

    // Concurrency level
    // how many browser should be started simultaneous
    concurrency: Infinity
  })
}
