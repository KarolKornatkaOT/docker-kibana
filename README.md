# Docker image containing kibana

Basic Docker image to run kibana on host

You need edit (add) this env:
- to set up exact kibana version ELASTICSEARCH url please edit KIBANA_VERSION or ELASTICSEARCH_URL var in Dockerfile

Example Usage: 
```
docker run -it -p 5901:5901 -d oberthur/docker-kibana

```
