FROM openjdk:14-jdk-alpine
RUN apk --no-cache add curl
RUN apk --no-cache add jq
COPY ./target/*jar /usr/app/app.jar
RUN curl -L https://dtdg.co/latest-java-tracer --output /usr/app/dd-java-agent.jar
WORKDIR /usr/app
EXPOSE 80
ENTRYPOINT [ "/bin/sh", "-c" , "\
  export IP_QUERY='.Containers[0].Networks[0].IPv4Addresses[0]' && \
  export IP_QUERY_HOST='http://169.254.170.2/v2/metadata' && \
  export DD_AGENT_HOST=$(curl $IP_QUERY_HOST | jq -r $IP_QUERY) && \
  export DD_TRACE_AGENT_PORT=8126 && \
  java \
    -javaagent:/usr/app/dd-java-agent.jar \
    -jar /usr/app/app.jar" ]