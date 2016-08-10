FROM geodata/gdal

USER root

RUN apt-get update && \
apt-get install cron && \
apt-get install -y postgresql-client && \
apt-get install -y curl && \
apt-get install -y nano && \
apt-get install -y zip

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash && \
apt-get install -y nodejs


#ADD /scripts /scripts
ENV DATABASE_URL postgres://postgres:postgres@mydatabase:5432/postgres


# Add crontab file in the cron directory
ADD crontab /etc/cron.d/hello-cron
 
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/hello-cron
 
# Create the log file to be able to run tail
RUN touch /var/log/cron.log
 
# Run the command on container startup
CMD cron && tail -f /var/log/cron.log
