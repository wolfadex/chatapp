const path = require('path');

module.exports = {
  mode: 'development',
  target: 'node',
  node: {
    __dirname: false,
  },
  entry: path.join(__dirname, 'src/server/index.js'),
  output: {
    path: path.join(__dirname, 'build'),
    filename: '[name].js',
  },
  externals: {
    uws: 'uws',
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: [
              [
                '@babel/preset-env',
                {
                  targets: {
                    node: 'current',
                  },
                },
              ],
            ],
          },
        },
      },
    ],
  },
};
