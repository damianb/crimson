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

note: requires [node-webkit](https://github.com/rogerwang/node-webkit/) 0.7.0+ to run compiled code

Due to coffee-script providing no programmatic wrapper for compiling coffee itself, we have to do stuff through shell processes.

Install nodejs (0.10) as per normal for your distro/OS, then, after ensuring that `~/node_modules/.bin/` is in your `$PATH`

```
$ cd
$ npm install -g coffee-script uglify-js less jade
```

(the above may require sudo, if you choose not to add `~/node_modules/.bin/` to your `$PATH`)

Next, install required dependencies.

```shell
$ git clone https://github.com/damianb/crimson.git
$ cd crimson; npm install
$ cake build
$ cd build; npm install
```

to run the application, cd to project directory and launch the build directory with the `nw` executable provided by node-webkit

### todo

* refactor for proper twitter support
* leverage twitter userstreams for max efficiency
* finish multi-column, multi-user support
* settings menus
* navigation icons
* logo
* keybase integration, gpg?   https://keybase.io/_/api/1.0/user/autocomplete.json?q=
