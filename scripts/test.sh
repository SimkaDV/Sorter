#!/bin/zsh
# Прогон тестов SorterCore. С Xcode достаточно `swift test`;
# с одними Command Line Tools нужно явно указать путь к Swift Testing.
set -e
cd "$(dirname "$0")/../SorterCore"
if [[ "$(xcode-select -p)" == *CommandLineTools* ]]; then
  D=/Library/Developer/CommandLineTools/Library/Developer
  exec swift test -Xswiftc -F$D/Frameworks -Xlinker -F$D/Frameworks \
    -Xlinker -rpath -Xlinker $D/Frameworks -Xlinker -rpath -Xlinker $D/usr/lib "$@"
else
  exec swift test "$@"
fi
