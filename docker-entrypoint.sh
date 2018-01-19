#!/bin/bash
set -e

# Allow to run complementary processes or to enter the container without
# running this init script.
if [ "$1" == '/usr/sbin/sshd' ]; then

  # Ensure time is in sync with host
  # see https://wiki.alpinelinux.org/wiki/Setting_the_timezone
  if [ -n ${TZ} ] && [ -f /usr/share/zoneinfo/${TZ} ]; then
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
    echo ${TZ} > /etc/timezone
  fi

  # Regenerate keys
  if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
  fi
  if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
  fi
  if [ ! -f "/etc/ssh/ssh_host_ecdsa_key" ]; then
    ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa
  fi

  # Create appropriate SFTP user
  useradd -u $OWNER_UID -M -d $FOLDER -g sftp -s /bin/false $USERNAME

  # Change sftp password
  if [ "$PASSWORD" != "" ]; then
    echo "$USERNAME:$PASSWORD" | chpasswd
  fi

  # Mount the data folder in the chroot folder
  if [ $CHROOT == 1 ]; then
    mkdir -p /chroot${FOLDER}
    mkdir -p $FOLDER
    sed -i -e 's|#ChrootDirectory|ChrootDirectory|' /etc/ssh/sshd_config
    mount --bind $FOLDER /chroot${FOLDER}
  fi

  # Allow using public key
  if [ "$PUBLIC_KEY" != "" ]; then
    mkdir -p $FOLDER/.ssh
    echo $PUBLIC_KEY > $FOLDER/.ssh/authorized_keys
    sed -i -e "s|#AuthorizedKeysFile.*|AuthorizedKeysFile $FOLDER/.ssh/authorized_keys|g" /etc/ssh/sshd_config
  fi

  # Change the default port
  if [ "$PORT" != '' ]; then
    sed "s|^Port.*|Port $PORT|" /etc/ssh/sshd_config
  fi

  # Add custom port here
  exec "$@" -p $PORT
else
  exec "$@"
fi


