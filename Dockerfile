#
# Teamcity, Scala, sbt and Elm
#
FROM jetbrains/teamcity-agent:latest

USER root

# Env variables
ENV SCALA_VERSION 2.13.3
ENV SBT_VERSION 1.3.12

RUN apt-get install curl software-properties-common

# Set Jdk 11
RUN \
    curl -fsL https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - && \
    add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ && \
    apt-get update && \
    apt-get install adoptopenjdk-11-hotspot -y

# Install sbt
RUN \
    curl -L -o sbt-$SBT_VERSION.deb https://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
    dpkg -i sbt-$SBT_VERSION.deb && \
    rm sbt-$SBT_VERSION.deb && \
    apt-get update && \
    apt-get install sbt rpm -y

# Install Scala
## Piping curl directly in tar
RUN \
    curl -fsL https://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz | tar xfz - -C /usr/share && \
    mv /usr/share/scala-$SCALA_VERSION /usr/share/scala && \
    chown -R root:root /usr/share/scala && \
    chmod -R 755 /usr/share/scala && \
    ln -s /usr/share/scala/bin/scala /usr/local/bin/scala

# Prepare sbt (warm cache)
RUN \
    sbt sbtVersion && \
    mkdir -p project && \
    echo "scalaVersion := \"${SCALA_VERSION}\"" > build.sbt && \
    echo "sbt.version=${SBT_VERSION}" > project/build.properties && \
    echo "case object Temp" > Temp.scala && \
    sbt compile && \
    rm -r project && rm build.sbt && rm Temp.scala && rm -r target


# Install Npm
RUN \
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install nodejs

# Prepare folder for global packages
RUN \
    mkdir "${HOME}/.npm-packages" && \
    npm config set prefix "${HOME}/.npm-packages" && \
    echo 'NPM_PACKAGES="${HOME}/.npm-packages"' >> "${HOME}/.bashrc" && \
    echo 'export PATH="$PATH:$NPM_PACKAGES/bin"' >> "${HOME}/.bashrc" && \
    echo 'export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"' >> "${HOME}/.bashrc"

RUN npm -v
RUN node -v

# Install Elm
RUN npm install -g elm@0.18 --unsafe-perm=true --allow-root
RUN npm install -g elm-test@0.18 --unsafe-perm=true --allow-root

# Switch working directory back to root
WORKDIR /root
