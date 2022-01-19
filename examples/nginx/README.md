# Prequisites

read [self-hosting docs](https://anonaddy.com/self-hosting/)

## Let's Encrypt

generate your certificates and make note of where they are stored. if you use certbot, they are generally in `/etc/letsencrypt/live`

## Generate strong dhparam

```sh
sudo openssl dhparam -out dhparam.pem 4096
```

## Configure mounts for nginx

the `docker-compose.yml` may need some adjusting to properly mount your specific let's encrypt and dhparam certs

## Rspamd web ui

this nginx configuration supports rspamd web ui out of the box. if you choose to not run rspamd, make sure to remove the `RSPAMD_ENABLE` variable in `anonaddy.env` and remove the proxy block in `nginx/templates/default.conf.template`
