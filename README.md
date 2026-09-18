<h1>Docker LAMP-Webserver on Debian based systems</h1>

![docker-lamp](docker-lamp.png)

This Dockerfile builds a basic **LAMP**-Stack (*Linux, Apache, MySQL, PHP*) Docker-image on **Debian** or **Ubuntu**.

<h2>Build the image</h2>

The default OS is Debian 12 (Bookworm)

```console
docker build -t lamp-server .
```

<h3>Build with other Debian-version</h3>

```console
docker build --build-arg OS_VERSION=trixie -t lamp-server .
```

<h3>Alternative: Build with Ubuntu</h3>

The OS and the Version can be changed by arguments. For example you can compile the image with Ubuntu 24.04.5

```console
docker build --build-arg OS_NAME=ubuntu --build-arg OS_VERSION=noble -t lamp-server .
```

<h3>Use another MySQL-Package</h3>

```console
docker build --build-arg MYSQL_PACKAGE=mysql-9.7-lts -t lamp-server .
```

See available MySQL-Packages here: [https://repo.mysql.com/apt/](https://repo.mysql.com/apt/)


<h2>Run the image</h2>

```console
docker run -itd --name lamp-server lamp-server
```

You can use more arguments for server configuration like bind-mount for Apache or MySQL-data etc.

`... -v $(PWD)/website:/usr/local/apache2/htdocs/`

<h2>Login into the container</h2>

```console
docker exec -it lamp-server /bin/bash
```

After the installation the basic Apache-webserver runs with *PhpMyAdmin* on `http://<your-server>/phpmyadmin` and must be configured. The MySQL-Rootpassword ist `rootROOT123!` and must be changed.

<h2>Annotations</h2>

<h3>Compatibilty</h3>

The Dockerfile build is tested with the images *Debian 12 (Bookworm)*, *Debian 13 (Trixie)*, *Ubuntu 24.04.5 (Noble Numbat)* and *Ubuntu 26.04.1 (Resolute Raccoon)*

*[tested on 09/18/2026 @ Host: Debian 6.12.41-1 / Debian GNU/Linux 13]*

<h3>Known error</h3>

```console
=> ERROR [ 6/23] RUN PUBKEY=$(apt-get update 2>&1 | sed -En 's/.*(NO_PUBKEY|Missing key) ([[:xdigit:]]+).*/\2
...
0.549 gpg: WARNING: nothing exported
0.562 gpg: no valid OpenPGP data found.
```

If the build breaks with a missing public key, you need to set the PUBKEY-value by yourself.

*(see NO_PUBKEY/Missing key with `apt-get update`)*


`
RUN PUBKEY=<insert public-key value here> \
&& gpg ...
`

<h3>Configuration</h3>

The Dockerfile compiles the basic *LAMP*-Server-image. The server still needs to be configured.

Please don't forget basic server security:

- Disable Server Signature and Banner
- Required Modules
- Disable Directory Listings
- Restrict Directory Access
- Protect Upload Directories
- HTTPS
- ...advanced security configuration, like Security Headers etc.
