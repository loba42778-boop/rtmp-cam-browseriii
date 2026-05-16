#!/usr/bin/env sh
# Gradle start-up script for UN*X (abridged official wrapper).
set -e
DIR=$(cd "$(dirname "$0")" && pwd)
APP_HOME=$DIR
CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar
exec "${JAVA_HOME:+$JAVA_HOME/bin/}java" \
  -Dorg.gradle.appname="gradlew" \
  -classpath "$CLASSPATH" \
  org.gradle.wrapper.GradleWrapperMain "$@"
