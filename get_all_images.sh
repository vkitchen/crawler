#!/bin/sh

for f in $1/*; do
  echo "./_build/default/get_image.exe $f $f.jpg"
  ./_build/default/get_image.exe "$f" "$f.jpg"
  sleep 1
done
