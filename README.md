SFTP dummy server for docker
======================
[![Build Status](https://travis-ci.org/CheckoutFinland/docker-dummy-sftp-server.svg?branch=master)](https://travis-ci.org/CheckoutFinland/docker-dummy-sftp-server)

This is used as a dummy sftp server in some of our integration tests.

## Description

This is a lightweight SFTP server in a docker container.

This image provides:
 - an alpine base image
 - SSH server
 - User creation based on env variable
 - Home directory based on env variable
 - Ability to run in chroot
 - Ability to use ssh public key

### Example

Mount contents of `./ssh-data` folder into sftp server inside container.

```yml
version: '2'

services:
  # SSHD Server
  sshtest:
    image: checkoutfinland/dummy-sftp-server
    environment:
      # (mandatory) Username for the login
      USERNAME: sftp
      # (optional) Use dummy ssh key you generated for this test
      PUBLIC_KEY: ssh-rsa AAAA....
      # (optional) Use custom path for AuthorizedKeysFile
      PUBLIC_KEYS_PATH: /etc/ssh/authorized_keys
      # (optional) Use the path of mapped volume, default: /in
      FOLDER: /in
      # (optional) put the $FOLDER inside chroot, default: 1
      CHROOT: 1
      # (optional) use custom port number, default: 22
      PORT: 2238
    cap_add:
      # Required if you want to chroot
      - SYS_ADMIN
    security_opt:
      # Required if you want to chroot
      - apparmor:unconfined
    ports:
      - 2238:2238
    volumes:
      ./ssh-data:/in
```

Verify that it works by opening sftp shell to the docker container with your ssh key:
```
$ sftp -oPort=2238 sftp@localhost:/in
```

### Configuration

Configuration is done through environment variables. 

Required:
- USERNAME: the name for login.
- PUBLIC_KEY: the public ssh key for login. (you need this or password)
- PASSWORD: the password for login. (you need this or public key)
- FOLDER: the home of the user.

Optional:
- CHROOT: if set to 1, enable chroot of user (prevent access to other folders than its home folder). Be aware, that 
currently this feature needs additionnal docker capabilities (see below).
- OWNER_ID: the uid of the user. If not set automatically grabbed from the uid of the owner of the FOLDER.

### Chroot 

If you want to run the SSH server with chroot feature, the docker image has to be run with additional capabilities.

    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined

This is due to the use of `mount --bind` in the init script.

**If someone has a better way to do, feel free to submit a pull request or a hint.**

## License

[GPLv2](http://www.fsf.org/licensing/licenses/info/GPLv2.html) or any later GPL version.
