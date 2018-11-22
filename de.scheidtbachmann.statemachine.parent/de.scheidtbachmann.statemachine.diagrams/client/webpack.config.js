const path = require('path');
const CopyWebpackPlugin = require('copy-webpack-plugin');

const buildRoot = path.resolve(__dirname, 'lib');
const appRoot = path.resolve(__dirname, 'page');
const bootstrapDistPath = 'node_modules/bootstrap/dist';
const jqueryDistPath = 'node_modules/jquery/dist';
const sprottyCssPath = 'node_modules/sprotty/css';
const elkWorkerPath = 'node_modules/elkjs/lib/elk-worker.min.js';

module.exports = function(env) {
    if (!env) {
        env = {}
    }
    return {
        entry: {
            diagrams: path.resolve(buildRoot, "main"),
        },
        output: {
            filename: 'bundle.js',
            path: appRoot
        },
        module: {
            rules: [
                {
                    test: /\.js$/,
                    loader: 'source-map-loader',
                    enforce: 'pre'
                    //, exclude: /..../
                }
            ]
        },
        resolve: {
            extensions: ['.js']
        },
        devtool: 'source-map',
        target: 'web',
        node: {
            fs: 'empty',
            child_process: 'empty',
            net: 'empty',
            crypto: 'empty'
        },
        plugins: [
            new CopyWebpackPlugin([
                {
                    from: bootstrapDistPath,
                    to: 'bootstrap'
                },
                {
                    from: jqueryDistPath,
                    to: 'jquery'
                },
                {
                    from: sprottyCssPath,
                    to: 'sprotty'
                },
                {
                    from: elkWorkerPath,
                    to: 'elk'
                }
            ])
        ]
    }
}