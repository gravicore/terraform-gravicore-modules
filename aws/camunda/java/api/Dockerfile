FROM openjdk:17-jdk-alpine
RUN apk --no-cache add curl
RUN apk --no-cache add jq
COPY ./target/*jar /usr/app/app.jar
RUN curl -L https://dtdg.co/latest-java-tracer --output /usr/app/dd-java-agent.jar
WORKDIR /usr/app
EXPOSE 80
ENTRYPOINT [ "/bin/sh", "-c" , "\
  java \
  -jar /usr/app/app.jar" ]
