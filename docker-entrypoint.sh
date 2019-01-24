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

  # Create appropriate SFTP user if it does not exist
  groups $USERNAME > /dev/null 2>&1 || useradd -u $OWNER_UID -M -d $FOLDER -g sftp -s /bin/false $USERNAME

  # Change sftp password and allow login with password
  if [ "$PASSWORD" != "" ]; then
    sed -i -e "s|^PasswordAuthentication.*|PasswordAuthentication yes|" /etc/ssh/sshd_config
  fi

  # If the user doesn't have a password we will get strange errors in sftp logs:
  # User $USERNAME not allowed because account is locked
  # If we set the password for the user we don't get that error
  PASSWORD=${PASSWORD-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10)}
  echo -e "$PASSWORD\n$PASSWORD" | passwd $USERNAME

  # Mount the data folder in the chroot folder
  if [ $CHROOT == 1 ]; then
    mkdir -p /chroot${FOLDER}
    mkdir -p $FOLDER
    sed -i -e 's|#ChrootDirectory|ChrootDirectory|' /etc/ssh/sshd_config
    mount --bind $FOLDER /chroot${FOLDER}
  fi

  # Allow overriding the default AuthorizedKeysFile path
  AUTHORIZED_KEYS_FILE=${PUBLIC_KEYS_FILE-$FOLDER/.ssh/authorized_keys}

  # Allow using public key
  if [ "$PUBLIC_KEY" != "" ]; then
    mkdir -p $(dirname $AUTHORIZED_KEYS_FILE)
    echo $PUBLIC_KEY >> $AUTHORIZED_KEYS_FILE
  fi

  # Allow mounting the authorized keys file from different path
  if [ "$PUBLIC_KEY" != "" ] || [ "$PUBLIC_KEYS_FILE" != "" ]; then
    sed -i -e "s|#AuthorizedKeysFile.*|AuthorizedKeysFile $AUTHORIZED_KEYS_FILE|g" /etc/ssh/sshd_config
  fi

  # Change the default port
  if [ "$PORT" != '' ]; then
    sed -i -e "s|^Port.*|Port $PORT|" /etc/ssh/sshd_config
  fi

  # Add custom port here
  exec "$@"
else
  exec "$@"
fi


