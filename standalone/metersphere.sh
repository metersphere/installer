#!/bin/sh

export JAVA_CLASSPATH=/metersphere:/opt/jmeter/lib/ext/*:/metersphere/lib/*
export JAVA_MAIN_CLASS=io.metersphere.Application
export JAVA_OPTIONS="-Dfile.encoding=utf-8 -Djava.awt.headless=true --add-opens java.base/jdk.internal.loader=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED"
sh /deployments/run-java.sh


