#! sh
lsc -c ./src/main.ls -o ./dist/
yuicompressor -o '.js$:.min.js' ./dist/main.js
