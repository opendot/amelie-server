#!/bin/bash

version=$(ls -1r '/usr/local/rvm/gems/' | egrep -m1 '^ruby-[0-9.]+$');

echo "VERSION: $version";

echo "START SYMLINK CREATION";

for tolink in $(ls "/usr/local/rvm/gems/$version/bin/")
do
    ln -s "/usr/local/rvm/gems/$version/bin/$tolink" "/usr/bin/$tolink";
done;
