FROM ubuntu:latest

LABEL \
  "maintainer"="Steve Harsant <contact@sharsant.com>" \
  "version"="1.0.0" \
  "description"="Modified minimal TeamCity agent with custom configuration"

ARG TEAMCITY_HOME="/opt/buildagent"

COPY assets/provision.sh /tmp/provision.sh
COPY assets/teamcity_buildagent.zip /tmp/teamcity_buildagent.zip

RUN bash /tmp/provision.sh

ENTRYPOINT /opt/buildagent/bin/agent.sh run
