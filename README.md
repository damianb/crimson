# crimson

desktop social network client, built using node-webkit, twit, and several other libraries.

targets:

* windows
* mac
* linux

*note*: linux support problematic due to an upstream issue regarding availability of older versions of `libudev.so` on modern distributions (see [issue](https://github.com/rogerwang/node-webkit/issues/770))

## license

original code available under MIT license

twitter bootstrap used under [Apache license 2.0](https://github.com/twitter/bootstrap/wiki/License)

### compiling

requires node-webkit 0.6.0+

to build latest changes, cd to project directory and use `cake build` or `cake watch` to build coffeescript, less, jade files used by crimson.

to run the application, cd to project directory and launch the build directory with the `nw` executable provided by node-webkit

### todo

* refactor for proper twitter support
* leverage twitter userstreams for max efficiency
* finish multi-column, multi-user support
* settings menus
* navigation icons
* logo
