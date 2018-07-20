## Status

Collector can run now. The problem is the docker related sources are not working in container mode. They can run in host mode with configuring daemon with a port and set tcp:// in source configuration. There are 2 possible approach here, 1) using `npipe://` - the latest docker engine support `-v //./pipe/docker_engine://./pipe/docker_engine` but it's not working in docker-java; 2) using `http://` - the problem is on Windows container the bridge network plugin is not working. Need a workaround to talk from container to the port on host  
