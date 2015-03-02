#!/bin/bash

rootDir="$1"
classpath=""

for jar in `find $rootDir -name "*.jar"`; do
  classpath="$jar:$classpath"
done

echo $classpath
