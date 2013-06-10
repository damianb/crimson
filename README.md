# crimson

desktop heello client, built using node-webkit, node-heello, and several other libraries.

targets:

* windows
* mac
* linux

*note*: linux support currently broken due to an upstream issue regarding availability of older versions of `libudev.so` on modern distributions (see [issue](https://github.com/rogerwang/node-webkit/issues/770))

## license

original code available under MIT license

twitter bootstrap used under [Apache license 2.0](https://github.com/twitter/bootstrap/wiki/License)

### compiling

requires node-webkit 0.5.1 (at least)

to build latest changes, cd to project directory and use `cake build` or `cake watch` to build coffeescript, less, jade files used by crimson.

to run the application, cd to project directory and launch the build directory with the `nw` executable provided by node-webkit
