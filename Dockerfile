FROM debian:stretch-slim
MAINTAINER Kamil Madac (kamil.madac@gmail.com)

# Apply source code patches
RUN mkdir -p /patches
COPY patches/* /patches/

RUN echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf && \
    echo 'APT::Get::Install-Suggests "false";' >> /etc/apt/apt.conf && \
    apt update; apt install -y ca-certificates wget python libpython2.7 nfs-common qemu-utils \
                               netbase; \
    update-ca-certificates; \
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py; \
    python get-pip.py; \
    rm get-pip.py; \
    wget https://raw.githubusercontent.com/openstack/requirements/stable/pike/upper-constraints.txt -P /app && \
    /patches/stretch-crypto.sh && \
    apt-get clean && apt autoremove && \
    rm -rf /var/lib/apt/lists/*; rm -rf /root/.cache

# Source codes to download
# commit Feb 2, 2018
ENV SVC_NAME=cinder
ENV REPO="https://github.com/openstack/$SVC_NAME" BRANCH="stable/pike" COMMIT="dee860c8cf4b"

# Install glance with dependencies
ENV BUILD_PACKAGES="git build-essential libssl-dev libffi-dev python-dev"

# Download source codes and install glance
RUN apt update; apt install -y $BUILD_PACKAGES && \
    if [ -z $REPO ]; then \
      echo "Sources fetching from releases $RELEASE_URL"; \
      wget $RELEASE_URL && tar xvfz $SVC_VERSION.tar.gz -C / && mv $(ls -1d $SVC_NAME*) $SVC_NAME && \
      cd /$SVC_NAME && pip install -r requirements.txt -c /app/upper-constraints.txt && /patches/patch.sh && PBR_VERSION=$SVC_VERSION python setup.py install; \
    else \
      if [ -n $COMMIT ]; then \
        cd /; git clone $REPO --single-branch --branch $BRANCH; \
        cd /$SVC_NAME && git checkout $COMMIT; \
      else \
        git clone $REPO --single-branch --depth=1 --branch $BRANCH; \
      fi; \
      cd /$SVC_NAME; pip install -r requirements.txt -c /app/upper-constraints.txt && /patches/patch.sh && python setup.py install && \
      rm -rf /$SVC_NAME/.git; \
    fi; \
    pip install supervisor PyMySQL python-memcached && \
    apt remove -y --auto-remove $BUILD_PACKAGES &&  \
    apt-get clean && apt autoremove && \
    rm -rf /var/lib/apt/lists/* && rm -rf /root/.cache

# prepare directories for storing image files and copy configs
RUN mkdir -p /var/lib/$SVC_NAME/images /etc/SVC_NAME /etc/supervisord /var/log/supervisord

# copy supervisor config
COPY configs/supervisord/supervisord.conf /etc

# copy configs
COPY configs/$SVC_NAME/ /etc/$SVC_NAME/

# external volume
VOLUME /$SVC_NAME-override

# copy startup scripts
COPY scripts /app

# Define workdir
WORKDIR /app
RUN chmod +x /app/*

ENTRYPOINT ["/app/entrypoint.sh"]

# Define default command.
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]
