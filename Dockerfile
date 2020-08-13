#
# Teamcity, Scala, sbt and Elm
#
FROM jetbrains/teamcity-agent:latest

USER root

# Env variables
ENV SCALA_VERSION 2.13.3
ENV SBT_VERSION 1.3.12
ENV USER_ID 1001
ENV GROUP_ID 1001

RUN apt-get install curl software-properties-common

# Set Jdk 11, we need to remove the old java from the path
RUN \
    apt-get update && \
    apt-get install openjdk-11-jdk -y && \
    echo 'export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> "${HOME}/.bashrc" && \
    echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/' >> "${HOME}/.bashrc" && \
    update-alternatives --auto java

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

# Install Npm
RUN \
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install nodejs

# Add and use user sbtuser
RUN groupadd --gid $GROUP_ID sbtuser && useradd --gid $GROUP_ID --uid $USER_ID sbtuser --shell /bin/bash
RUN chown -R sbtuser:sbtuser /opt
RUN mkdir /home/sbtuser && chown -R sbtuser:sbtuser /home/sbtuser
RUN mkdir /logs && chown -R sbtuser:sbtuser /logs
USER sbtuser

# Switch working directory
WORKDIR /home/sbtuser

# Prepare sbt (warm cache)
RUN \
    sbt sbtVersion && \
    mkdir -p project && \
    echo "scalaVersion := \"${SCALA_VERSION}\"" > build.sbt && \
    echo "sbt.version=${SBT_VERSION}" > project/build.properties && \
    echo "case object Temp" > Temp.scala && \
    sbt compile && \
    rm -r project && rm build.sbt && rm Temp.scala && rm -r target

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
