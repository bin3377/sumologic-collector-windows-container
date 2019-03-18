@echo off
docker build --no-cache=true -f ./Dockerfile -t sumologic/collector-win-beta .

REM docker run -it -u ContainerAdministrator -v //./pipe/docker_engine://./pipe/docker_engine sumologic/collector-win-beta