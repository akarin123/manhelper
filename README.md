# Man Helper
Man Helper is a lightweight GUI front-end for man2html under development using Vala and GTK. It features an easy-to-use interface, and aims for a modern GUI viewer for man pages.
![Man Helper Screenshot](./manhelper_screenshot.png?style=centerme "Man Helper running on Linux Mint"){width=75% height=75%}

## Building and Installation
You'll need the following dependencies to build:

* gobject-introspection
* libgda-5.0-dev
* libgtk-3-dev (>= 3.24.0)
* libjson-glib-dev
* libsoup2.4-dev
* libwebkit2gtk-4.0-dev
* libxml2-dev
* meson
* valac

You'll need the following dependencies to run:

* apache2
* man2html

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `com.github.manhelper`

    ninja install
    com.github.manhelper

## Features

- [x] GUI front-end
- [x] find in man page
- [x] search in man database
- [x] bookmarks
- [x] multi-tab views
- [x] zoom in/out
- [ ] preferences (font family, theme color, etc)
- [ ] color marking
- [ ] translation
