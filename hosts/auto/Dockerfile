FROM ubuntu:latest

LABEL \
  "maintainer"="Steve Harsant <contact@sharsant.com>" \
  "version"="1.0.0" \
  "description"="Modified minimal TeamCity agent with custom configuration"

ARG TEAMCITY_URL
ENV TEAMCITY_URL=${TEAMCITY_URL}

COPY assets/provision.sh /tmp/provision.sh
RUN bash /tmp/provision.sh

ENTRYPOINT /opt/buildagent/bin/agent.sh run
