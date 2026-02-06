FROM alpine:latest
RUN adduser -D alice
RUN mkdir -p /home/alice && echo "FLAG{Interesting_stuff_can_be_hidden_in_image_files}" > /home/alice/flag.txt && chown -R alice:alice /home/alice
COPY sp-creds.json /tmp/sp-creds.json
RUN cat /tmp/sp-creds.json >> /home/alice/logic_app_creds.json
RUN apk add --no-cache bash coreutils curl wget iputils busybox-extras procps
CMD ["/bin/bash"]
