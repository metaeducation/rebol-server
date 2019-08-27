# rebol-server

This repository contains bash scripts for creating a small Android .APK
package, that bundles an ARM-based Rebol interpreter ["Ren-C branch"][1]) with
a very tiny web server (implemented in Rebol).

Then it also includes a *second* Rebol interpreter, which is compiled to
[WebAssembly][2]...plus a cache of a web-based interactive console called
[Replpad-JS][3].

[1]: https://github.com/metaeducation/ren-c
[2]: https://webassembly.org/
[3]: https://github.com/hostilefork/replpad-js

Rebol interpreters pride themselves on being small--so it's not a big deal to
have two of them in the package.  But...why, especially considering that you
can simply run ReplPad-JS from the network using the phone's native browser?

Because:

* When the phone itself is serving the HTML, JS, and WebAssembly for the
  console, it can be used even when the phone is offline.

* There is a kind of an "app store" concept--where GitHub repositories
  containing other interesting Rebol code besides the console can be downloaded
  and cached locally as well.

* The Android-native interpreter that is doing the local serving can act as a
  backchannel for capabilities that an ordinary website couldn't do.  Examples
  would be reading or writing files from the phone's internal storage, or
  fetching URLs that are not CORS-enabled.

*(Note: Since such backchannels can ultimately represent security risks, use
good judgment--as you would with any programming tool--when it comes to running
code from untrusted sources!!!)*


## Building the .APK

You should be able to run the bash scripts on pretty much any Linux.  But they
are designed to be able to run even on something like [Termux][4], so you can
even build the .APK on the phone itself!!

The scripts just pull down the latest executable from [Ren-C's Travis][5], so
there's no need to do any C compilation of Rebol itself on the phone (although
you certainly can!).

[4]: https://termux.com/
[5]: https://travis-ci.org/metaeducation/ren-c

So really the main thing to do is make sure you have the right Android packing
tools installed.  You'll need to `apt install` the following:

* `zip`
* `dx`
* `apksigner`
* `zipalign`

Which Java you install depends on if you are making the package on your phone
via Termux, or just using an ordinary Linux:

* If using Linux: `javac`
* If using Termux: `ecj`

If all those dependencies are in place, you can run `bash build.bash` and it
should "just work".  If not, please raise an issue:

https://github.com/metaeducation/rebol-server/issues


## License

* Rebol 3 (including the Ren-C branch) is covered by the [Apache 2 License][6]
* The Rebol JavaScript extension is covered by the [LGPL 3.0][7]
* ReplPad-JS is also LGPL 3.0.

The rebol-server packaging code is Copyright (c) 2019 by Giulio Lunati, and is
another LGPL 3.0 project.

Any "apps" that are cached and interact with the rebol-server are governed by
whatever license they state.

[6]: https://www.apache.org/licenses/LICENSE-2.0
[7]: https://www.gnu.org/licenses/lgpl-3.0.en.html


## Future Directions

It would be nice if the bash scripts were ported to Rebol. :-)  It would also
be good if the packaging process didn't need to depend on Java or other
languages.  (So having something like a `%jarsigner.reb`.)

Right now, the Android build of Rebol is really just a typical POSIX target.
So the number of "superpowers" it is able to grant to the web app are pretty
much limited to local file access--as well as more generalized network access
than is available to the average website.

However...it would be possible to create "extensions" that would use APIs from
the [Android NDK][8].  That would permit the Rebol webserver to do things like
take pictures, or read the GPS, or whatever.

[8]: https://developer.android.com/ndk

One area that is **not** likely to be of much interest (to the core Rebol/Ren-C
developers) is trying to work with native Android GUI widgets.  That's because
the aim of this project is largely to embrace the trend toward browser-based
development, and "Progressive Web Apps":

https://en.wikipedia.org/wiki/Progressive_web_applications

...but the hope is to try doing so with a WebAssembly-based Rebol playing a big
role in that picture!
