#!/bin/sh

export JAVA_CLASSPATH=/result-hub:/opt/jmeter/lib/ext/*:/result-hub/lib/*
export JAVA_MAIN_CLASS=io.metersphere.result.Application
export JAVA_OPTIONS="-Dfile.encoding=utf-8 -Djava.awt.headless=true --add-opens java.base/jdk.internal.loader=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED"
sh /deployments/run-java.sh


