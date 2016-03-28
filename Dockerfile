FROM java:8-jdk

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV GLASSFISH_HOME /usr/local/glassfish4
ENV PATH $PATH:$JAVA_HOME/bin:$GLASSFISH_HOME/bin
ENV GLASSFISH_URL http://download.oracle.com/glassfish/4.1.1/release/glassfish-4.1.1-web.zip
ENV PASSWORD glassfish

RUN apt-get update && \
  apt-get install -y curl unzip zip inotify-tools && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/glassfish4

COPY customization.txt /tmp/customization.txt

RUN curl -L -o /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.0.1/dumb-init_1.0.1_amd64; \
  chmod +x /usr/local/bin/dumb-init \
  curl -L -o /tmp/glassfish-4.1.zip http://download.java.net/glassfish/4.1/release/glassfish-4.1.zip && \
  unzip /tmp/glassfish-4.1.zip -d /usr/local && \
  rm -f /tmp/glassfish-4.1.zip && \
  echo "--- Setup the password file ---" && \
  echo "AS_ADMIN_PASSWORD=" > /tmp/glassfishpwd && \
  echo "AS_ADMIN_NEWPASSWORD=${PASSWORD}" >> /tmp/glassfishpwd  && \
  echo "--- Enable DAS, change admin password, and secure admin access ---" && \
  asadmin --user=admin --passwordfile=/tmp/glassfishpwd change-admin-password --domain_name domain1 && \
  asadmin start-domain && \
  echo "AS_ADMIN_PASSWORD=${PASSWORD}" > /tmp/glassfishpwd && \
  asadmin --user=admin --passwordfile=/tmp/glassfishpwd < /tmp/customization.txt && \
  asadmin --user=admin stop-domain && \
  rm /tmp/glassfishpwd && \
  rm /tmp/customization.txt

EXPOSE 4848 8080 8181

# RUN cp *.jar $WORKDIR/glassfish/domains/domain1/lib/ext

VOLUME /usr/local/glassfish4/glassfish/domains/domain1

CMD ["dumb-init", "asadmin", "start-domain", "--verbose"]
