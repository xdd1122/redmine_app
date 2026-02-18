FROM alpine:latest

RUN apk add --no-cache postgresql-client aws-cli bash

# Add script
COPY script.sh /script.sh
RUN chmod +x /script.sh

# Run
CMD ["/script.sh"]
