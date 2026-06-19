FROM alpine/java:17-jdk
RUN apk --no-cache add curl
RUN apk --no-cache add jq
COPY ./target/*jar /usr/app/app.jar
WORKDIR /usr/app
EXPOSE 80
ENTRYPOINT [ "/bin/sh", "-c" , "\
  java \
  -jar /usr/app/app.jar" ]
