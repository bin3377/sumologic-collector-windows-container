@echo off
docker build --no-cache=true -f ./Dockerfile -t sumologic/collector-win-beta .