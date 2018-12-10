FROM alpine
MAINTAINER Onni Hakala <onni.hakala@checkout.fi>
# shadow is required for usermod
# tzdata for time syncing
# bash for entrypoint script
RUN apk add --no-cache openssh bash shadow tzdata

# Ensure key creation
RUN rm -rf /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_ecdsa_key

# Don't create mailboxes for users
RUN sed -i 's/^CREATE_MAIL_SPOOL=yes/CREATE_MAIL_SPOOL=no/' /etc/default/useradd
RUN addgroup sftp

# Create entrypoint script
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# SSH Server configuration file
COPY sshd_config /etc/ssh/sshd_config

# Default environment variables
ENV TZ="Europe/Helsinki" \
    LANG="C.UTF-8" \
    FOLDER="/in" \
    OWNER_UID=1000 \
    CHROOT=1 \
    PORT=22 \
    USERNAME=sftp

EXPOSE 22
ENTRYPOINT [ "/docker-entrypoint.sh" ]

# RUN SSH in no daemon and expose errors to stdout
CMD [ "/usr/sbin/sshd", "-D", "-e" ]
