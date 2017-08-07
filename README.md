## Cinder docker container

### Using

```
git clone https://gitlab.com/DietStack/docker-cinder.git
cd docker-glance
./build.sh
```
Result will be cinder image in a local image registry.

# Development
There is a script called `test.sh`. This can be used either for development or testing. By default, script runs couple of docker containers (galera, memcached, keystone, glance), make tests and removes containers. This is used for testing purposes (also in CI).
When you run the script with parameter noclean, it'll build environment, runs all tests and leave all dockers running. This is usefol for development of glance containers.

