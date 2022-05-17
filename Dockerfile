FROM clojure:openjdk-11-tools-deps-bullseye AS BASE

ARG TARGETARCH

# Setup GraalVM
RUN apt-get update
RUN apt-get install --no-install-recommends -yy curl unzip build-essential zlib1g-dev
WORKDIR "/opt"
RUN export GRAALVM_ARCH=$(echo $TARGETARCH | sed -e 's/arm64/aarch64/g'); curl -sLO https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.1.0/graalvm-ce-java11-linux-${GRAALVM_ARCH}-22.1.0.tar.gz
RUN export GRAALVM_ARCH=$(echo $TARGETARCH | sed -e 's/arm64/aarch64/g'); tar -xzf graalvm-ce-java11-linux-${GRAALVM_ARCH}-22.1.0.tar.gz
ENV GRAALVM_HOME="/opt/graalvm-ce-java11-22.1.0"
RUN $GRAALVM_HOME/bin/gu install native-image

# Cache dependencies
COPY ./deps.edn ./deps.edn
RUN clojure -R:test:native-image -e ""
COPY . .

# Run tests
RUN clojure -Mtest

# Build binary
ARG GIT_REF
RUN clojure -Mnative-image -Dversion=$(echo $GIT_REF | cut -d/ -f3-)


# Create minimal image
FROM busybox:1.31.1-glibc
COPY --from=BASE /opt/prometheus_pushgateway_cleaner /usr/bin/prometheus_pushgateway_cleaner
ENTRYPOINT ["prometheus_pushgateway_cleaner"]
