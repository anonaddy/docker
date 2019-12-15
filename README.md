<p align="center"><a href="https://github.com/crazy-max/docker-anonaddy" target="_blank"><img height="128" src="https://raw.githubusercontent.com/crazy-max/docker-anonaddy/master/.res/docker-anonaddy.jpg"></a></p>

<p align="center">
  <a href="https://hub.docker.com/r/crazymax/anonaddy/tags?page=1&ordering=last_updated"><img src="https://img.shields.io/github/v/tag/crazy-max/docker-anonaddy?label=version&style=flat-square" alt="Latest Version"></a>
  <a href="https://github.com/crazy-max/docker-anonaddy/actions?workflow=build"><img src="https://github.com/crazy-max/docker-anonaddy/workflows/build/badge.svg" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/crazymax/anonaddy/"><img src="https://img.shields.io/docker/stars/crazymax/anonaddy.svg?style=flat-square" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/crazymax/anonaddy/"><img src="https://img.shields.io/docker/pulls/crazymax/anonaddy.svg?style=flat-square" alt="Docker Pulls"></a>
  <a href="https://www.codacy.com/app/crazy-max/docker-anonaddy"><img src="https://img.shields.io/codacy/grade/2816d13dcb64417eb71783a16e12a777.svg?style=flat-square" alt="Code Quality"></a>
  <br /><a href="https://github.com/sponsors/crazy-max"><img src="https://img.shields.io/badge/sponsor-crazy--max-181717.svg?logo=github&style=flat-square" alt="Become a sponsor"></a>
  <a href="https://www.paypal.me/crazyws"><img src="https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal&style=flat-square" alt="Donate Paypal"></a>
</p>

> :warning: **This repository is a draft to make it possible to port AnonAddy to a Docker image. Some features have not yet been tested or are missing. Therefore, this image is not ready for production.**

## About

🐳 [AnonAddy](https://anonaddy.com/) Docker image based on Alpine Linux.<br />
If you are interested, [check out](https://hub.docker.com/r/crazymax/) my other 🐳 Docker images!

💡 Want to be notified of new releases? Check out 🔔 [Diun (Docker Image Update Notifier)](https://github.com/crazy-max/diun) project!

## Features

* Run as non-root user
* Multi-platform image
* [s6-overlay](https://github.com/just-containers/s6-overlay/) as process supervisor
* [Traefik](https://github.com/containous/traefik-library-image) as reverse proxy and creation/renewal of Let's Encrypt certificates (see [this template](examples/traefik))

## Docker

### Multi-platform image

Following platforms for this image are available:

```
$ docker run --rm mplatform/mquery crazymax/anonaddy:latest
Image: crazymax/anonaddy:latest
 * Manifest List: Yes
 * Supported platforms:
   - linux/amd64
   - linux/arm/v6
   - linux/arm/v7
   - linux/arm64
   - linux/386
   - linux/ppc64le
```

### Environment variables

#### General

* `TZ`: The timezone assigned to the container (default `UTC`)
* `PUID`: AnonAddy user id (default `1000`)
* `PGID`: AnonAddy group id (default `1000`)
* `MEMORY_LIMIT`: PHP memory limit (default `256M`)
* `UPLOAD_MAX_SIZE`: Upload max size (default `16M`)
* `OPCACHE_MEM_SIZE`: PHP OpCache memory consumption (default `128`)
* `REAL_IP_FROM`: Trusted addresses that are known to send correct replacement addresses (default `0.0.0.0/32`)
* `REAL_IP_HEADER`: Request header field whose value will be used to replace the client address (default `X-Forwarded-For`)
* `LOG_IP_VAR`: Use another variable to retrieve the remote IP address for access [log_format](http://nginx.org/en/docs/http/ngx_http_log_module.html#log_format) on Nginx. (default `remote_addr`)

#### App

* `APP_KEY`: Application key for encrypter service. You can generate one through `php artisan key:generate --show` command **required**
* `APP_DEBUG`: Enables or disables debug mode, used to troubleshoot issues (default `false`)
* `APP_URL`: The URL of your AnonAddy installation

#### AnonAddy

* `ANONADDY_RETURN_PATH`: Return-path header for outbound emails
* `ANONADDY_ADMIN_USERNAME`: If set this value will be used and allow you to receive forwarded emails at the root domain
* `ANONADDY_ENABLE_REGISTRATION`: If set to false this will prevent new users from registering on the site (default `false`)
* `ANONADDY_DOMAIN`: Root domain to receive email from
* `ANONADDY_HOSTNAME`: FQDN hostname for your server used to validate records on custom domains that are added by users
* `ANONADDY_DNS_RESOLVER`: Custom domains that are added by users to validate records (default `127.0.0.1`)
* `ANONADDY_ALL_DOMAINS`: Other domains to use
* `ANONADDY_SECRET`: Long random string used when hashing data for the anonymous replies **required**
* `ANONADDY_LIMIT`: Number of emails a user can forward and reply per hour (default `200`)
* `ANONADDY_BANDWIDTH_LIMIT`: Monthly bandwidth limit for users in bytes domains to use (default `104857600`)
* `ANONADDY_NEW_ALIAS_LIMIT`: Number of new aliases a user can create each hour (default `10`)
* `ANONADDY_ADDITIONAL_USERNAME_LIMIT`: Number of additional usernames a user can add to their account (default `3`)
* `ANONADDY_SIGNING_KEY_FINGERPRINT`: GPG key used to sign forwarded emails. Should be the same as your mail from email address

#### Database

* `DB_HOST`: MySQL database hostname / IP address **required**
* `DB_PORT`: MySQL database port (default `3306`)
* `DB_DATABASE`: MySQL database name (default `anonaddy`)
* `DB_USERNAME`: MySQL user (default `anonaddy`)
* `DB_PASSWORD`: MySQL password
* `DB_TIMEOUT`: Time in seconds after which we stop trying to reach the MySQL server (useful for clusters, default `60`)

#### Redis

* `REDIS_HOST`: Redis hostname / IP address
* `REDIS_PORT`: Redis port (default `6379`)
* `REDIS_PASSWORD`: Redis password

#### Mail

* `MAIL_HOST`: SMTP hostname / IP address
* `MAIL_PORT`: SMTP port (default `25`)
* `MAIL_USERNAME`: SMTP username
* `MAIL_PASSWORD`: SMTP password
* `MAIL_ENCRYPTION`: SMTP encryption protocol
* `MAIL_FROM_NAME`: From name (default `AnonAddy`)
* `MAIL_FROM_ADDRESS`: Frtom email address

### Volumes

* `/data`: Contains storage

> :warning: Note that the volume should be owned by the user/group with the specified `PUID` and `PGID`. If you don't give the volume correct permissions, the container may not start.

### Ports

* `2500`: SMTP port
* `8000`: HTTP port

## Usage

### Docker Compose

Docker compose is the recommended way to run this image. You can use the following [docker compose template](examples/compose/docker-compose.yml), then run the container:

```bash
docker-compose up -d
docker-compose logs -f
```

## Upgrade

You can upgrade AnonAddy automatically through the UI, it works well. But I recommend to recreate the container whenever I push an update:

```bash
docker-compose pull
docker-compose up -d
```

## Notes

### First launch

On first launch you have to create an admin user with the following command:

```
docker-compose exec --user anonaddy anonaddy php artisan db:seed
```

Then try to connect to your AnonAddy instance with `anonaddy`/`anonaddy` credentials.

## How can I help ?

All kinds of contributions are welcome :raised_hands:! The most basic way to show your support is to star :star2: the project, or to raise issues :speech_balloon: You can also support this project by [**becoming a sponsor on GitHub**](https://github.com/sponsors/crazy-max) :clap: or by making a [Paypal donation](https://www.paypal.me/crazyws) to ensure this journey continues indefinitely! :rocket:

Thanks again for your support, it is much appreciated! :pray:

## License

MIT. See `LICENSE` for more details.
