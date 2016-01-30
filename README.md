# Springseed
[![Stories in Ready](https://badge.waffle.io/byhestia/springseed.svg?label=ready&title=Ready)](http://waffle.io/byhestia/springseed) 

**Current version: 2.0**

Springseed is the simple and easy way to take your notes.

# Binaries

A fairly up-to-date build is available [here](https://xack.xyz/misc/springeed.zip).

1. Extract `springseed.zip` into its own directory.
2. `./run.sh` **should** download atom-shell, extract it, then run the app.

If there are any issues, please don't hesitate to submit a bug report.

## Preparing Springseed

Springseed is now based on the awesome work of the people at GitHub and as
such we use the fantastic `electron` framework to get stuff done. 

### Installing `electron`
(If you already have `electron` jump to the next section)

Latest builds of `electron` are available [here](https://github.com/atom/electron/releases).
* Download the appropriate file based on your operating system and the system architecture.
* Unzip the downloaded file. This must create an executable file named `electron`.

### Building this code
We have introduced a new build system based on the GNU Makefile build system. Should the
build below fail, you should run `make clean` before trying again because some
make operations won't complete if they've errored. Nothing we can do to fix
this. :smile:

    sudo gem install sass
    git submodule update --init
    make

## Running Springseed
To start Springseed, run the command `<path-to-electron-executable>/electron <springseed-build-directory>` where `<springseed-build-directory>` is the directory where you executed the three commands in **Building this code** section


If you're feeling awesome, you should contribute either with code or a
[donation][1]. Check out the [issue tracker][2] and tackle an issue.

Springseed is written in CoffeeScript and uses Spine.JS for MVC.

## Official website

<http://getspringseed.com>

Copyright &copy; 2013-2014 [Caffeinated Code][3]<br>
Copyright &copy; 2014 [Hestia][4]

Open source under the [MIT license][5].

[1]: http://getspringseed.com/donate
[2]: https://github.com/byhestia/springseed
[3]: http://www.caffeinatedco.de/
[4]: http://byhestia.com/
[5]: http://opensource.org/licenses/MIT
