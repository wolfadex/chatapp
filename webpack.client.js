const path = require('path');

module.exports = {
  mode: 'development',
  entry: path.join(__dirname, 'src/client/js/index.js'),
  output: {
    path: path.join(__dirname, 'build/public'),
    filename: 'bundle.js',
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
              '@babel/preset-env',
            ],
          },
        },
      },
    ],
  },
};
