// const MonacoWebPackPlugin = require('monaco-editor-webpack-plugin');
const path = require('path');

module.exports = {
  mode: 'development', // 'production', 'development', 'none'
  // enntry file
  entry: {
    "tshasio": './src/tshasio.ts',
    "jshasio" : './src/jshasio.js',
    "hasio-monaco" : './src/monaco.js',
		"editor.worker": 'monaco-editor/esm/vs/editor/editor.worker.js',
		"json.worker": 'monaco-editor/esm/vs/language/json/json.worker',
		"css.worker": 'monaco-editor/esm/vs/language/css/css.worker',
		"html.worker": 'monaco-editor/esm/vs/language/html/html.worker',
		"ts.worker": 'monaco-editor/esm/vs/language/typescript/ts.worker',
  },
  // 컴파일 + 번들링된 js 파일이 저장될 경로와 이름 지정
  output: {
		globalObject: 'self',
    filename: '[name].bundle.js',
    path: path.resolve(__dirname, 'dist'),
    publicPath: '/dist'
  },
  module: {
    rules: [
			{
				test: /\.tsx?$/i,
				loader: 'ts-loader',
        include: [
          path.resolve(__dirname, 'src'),
          path.resolve(__dirname, 'test')
        ],
				exclude: [/node_modules/]
			},
      {
        test: /\.jsx?$/i,
        include: [
          path.resolve(__dirname, 'src'),
          path.resolve(__dirname, 'test')
        ],
        exclude: [/(node_modules|bower_components)/],
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env'],
           // plugins: ['@babel/plugin-proposal-class-properties']
          }
        }
      },
			{
				test: /\.html$/i,
				loader: 'html-loader',
				include: [path.resolve(__dirname, 'src')],
				exclude: [/node_modules/]
			},
      {
        test: /\.css$/i,
        use: ['style-loader','css-loader'],
      }
    ]
  },
  // 이것을 빼먹으면 테스트를 못한다.
  resolve: {
    extensions: ['.ts', '.js', '.json']
  },
  // plugins: [
  //   new MonacoWebPackPlugin()
  // ],
  devtool: 'inline-source-map'
};