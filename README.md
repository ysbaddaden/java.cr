# Java Native Interface (JNI) bindings (and generator) for Crystal

Generate Java bindings through the Java Native Interface (JNI) automatically
from Java classes using the `javap` tool distributed with the JDK.

The main goal is to generate bindings for the Android SDK. This project is thus
for the most usable widget and communication classes (e.g.
`android.app.Activity`, `android.os.Handler` or `android.widget.TextView`).
More complex classes, mostly those relying on generics and wildcards will
probably fail, or generate invalid Crystal code.

## Install

Add the shard to your `shard.yml` dependencies:

```
dependencies:
  java:
    github: ysbaddaden/java.cr
```

## Usage

Let's generate some bindings for an Android project. First we must add the
target platform `android.jar` to `CLASSPATH`. For example. Let's also add the
project local folder where the Android SDK will store the compiled classes.

```sh
export CLASSPATH=bin/classes:/opt/android-sdk/platforms/android-23/android.jar
```

Let's generate some bindings, this will load the definition of the specified
classes, potentially following classes found, then generate the Crystal bindings
into namespace separated folders. Pass `--help` for the full list of options.

```sh
lib/java/bin/generator --output src --no-follow \
    android.app.Activity \
    android.os.Bundle \
    android.os.Message \
    android.os.Handler
```

You may now just use it:

```crystal
require "android/os/bundle"
require "android/os/message"

bundle = Android::Os::Bundle.new
bundle.put_char_sequence("action", "setText")
bundle.put_char_sequence("text", "hello world")

message = Android::Os::Message.new
message.set_data(bundle)
```

## TODO

- [ ] fix bugs
- [ ] write tests


## Authors

- Julien Portalier (creator, maintainer)
