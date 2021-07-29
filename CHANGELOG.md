# Changelog

## 0.8.0-r0 (2021/07/29)

* AnonAddy 0.8.0 (#65)
* Fix Postfix hostname (#67)
* Drop `linux/ppc64le` and `linux/s390x` platforms support

## 0.7.5-r0 (2021/07/04)

* AnonAddy 0.7.5 (#64)

## 0.7.4-r0 (2021/06/13)

* AnonAddy 0.7.4 (#63)
* Fix charset (#62)
* Drop `block_alias` procedure (#58)
* Fix `opendmarc` and `php7-imagick` pkg (#60)
* Remove `linux/386` support (#61)

## 0.7.3-r0 (2021/05/27)

* AnonAddy 0.7.3

## 0.7.2-r2 (2021/04/16)

* alpine-s6 3.13-2.2.0.3 (#54)
* Handle GPG keys (#53)
* Add Postfix relayhost configuration variables (#50)
* Add apex domain to signing table (#51)

## 0.7.2-r1 (2021/03/18)

* Upstream Alpine update

## 0.7.2-r0 (2021/03/10)

* AnonAddy 0.7.2

## 0.7.1-r3 (2021/03/02)

* Renamed `yasu` (more info https://github.com/crazy-max/yasu#yet-another)

## 0.7.1-r2 (2021/03/02)

* Switch to `gosu`

## 0.7.1-r1 (2021/02/28)

* Fix permissions

## 0.7.1-r0 (2021/02/26)

* AnonAddy 0.7.1

## 0.7.0-r4 (2021/02/16)

* Alpine Linux 3.13
* alpine-s6 2.2.0.3
* Switch to buildx bake

## 0.7.0-RC3 (2021/01/10)

* Display postfix logs through socklog
* Disable socklog timestamp

## 0.7.0-RC2 (2021/01/10)

* Fix DKIM key table
* Clear view and route cache
* Add `DKIM_ENABLE` env var
* Review milter configuration
* Fix openDMARC and openDKIM sockets
* Fix openDKIM permissions

## 0.7.0-RC1 (2021/01/08)

* AnonAddy 0.7.0
* Add support for DKIM and DMARC (#35)

## 0.6.2-RC1 (2021/01/06)

* AnonAddy 0.6.2
* Alpine Linux edge (need PHP 7.4)

## 0.6.0-RC5 (2020/11/25)

* Enable gnupg extension (#34)

## 0.6.0-RC4 (2020/11/12)

* Handle domains in virtual_mailbox_domains (#32)

## 0.6.0-RC3 (2020/10/25)

* Fix mail forwarding (#29 #30)

## 0.6.0-RC2 (2020/10/16)

* Fix stored procedure

## 0.6.0-RC1 (2020/10/16)

* AnonAddy 0.6.0
* Add env var to clear environment in FPM workers

## 0.5.0-RC1 (2020/10/09)

* AnonAddy 0.5.0

## 0.4.0-RC1 (2020/10/08)

* AnonAddy 0.4.0

## 0.3.0-RC1 (2020/09/28)

* AnonAddy 0.3.0

## 0.2.13-RC1 (2020/09/21)

* AnonAddy 0.2.13
* Handle multi domains (anonaddy/anonaddy#49)
* Set `ANONADDY_DOMAIN` as default value of `ANONADDY_ALL_DOMAINS` (#24)

## 0.2.12-RC1 (2020/09/17)

* AnonAddy 0.2.12

## 0.2.11-RC2 (2020/09/10)

* Remove permit_mynetworks from smtpd_recipient_restrictions (anonaddy/anonaddy#72)
* Switch to Docker actions

## 0.2.11-RC1 (2020/08/25)

* AnonAddy 0.2.11

## 0.2.10-RC2 (2020/08/21)

* Add private CIDR to the list of "trusted" remote SMTP clients for Postfix (#22)

## 0.2.10-RC1 (2020/08/20)

* AnonAddy 0.2.10

## 0.2.9-RC3 (2020/08/19)

* Fix UID/GID perms (#21)

## 0.2.9-RC2 (2020/08/19)

* Fix perms (#20)

## 0.2.9-RC1 (2020/08/18)

* AnonAddy 0.2.9
* Repo moved to [anonaddy/docker](https://github.com/anonaddy/docker)

## 0.2.8-RC6 (2020/08/08)

* Now based on [Alpine Linux 3.12 with s6 overlay](https://github.com/crazy-max/docker-alpine-s6/)

## 0.2.8-RC5 (2020/08/01)

* Remove database seed and enable registration by default

## 0.2.8-RC4 (2020/07/22)

* Typo

## 0.2.8-RC3 (2020/07/21)

* Switch to single container
* Use `sendmail` SMTP driver
* Rename `SMTP_DEBUG` to `POSTFIX_DEBUG`
* Add `POSTFIX_SMTPD_TLS`, `POSTFIX_SMTPD_TLS_CERT_FILE`, `POSTFIX_SMTPD_TLS_KEY_FILE` and `POSTFIX_SMTP_TLS` env vars

## 0.2.8-RC2 (2020/07/21)

* Add `SMTP_DEBUG` env var
* Fix Postfix main configuration
* Force SMTP port to `25`
* Remove `MAIL_PORT` and `SMTP_PORT` env vars
* `ANONADDY_DOMAIN` env var required

## 0.2.8-RC1 (2020/06/24)

* AnonAddy 0.2.8
* Create anonaddy command
* Alpine Linux 3.12

## 0.2.5-RC3 (2020/05/17)

* Add `LISTEN_IPV6` env var

## 0.2.5-RC2 (2020/03/29)

* Use SMTP driver (#10)

## 0.2.5-RC1 (2020/03/27)

* AnonAddy 0.2.5
* Fix folder creation

## 0.2.4-RC1 (2020/02/29)

* AnonAddy 0.2.4

## 0.2.3-RC1 (2020/02/18)

* AnonAddy 0.2.3

## 0.2.2-RC1 (2020/02/14)

* AnonAddy 0.2.2

## 0.1.6-RC1 (2020/02/11)

* AnonAddy 0.1.6

## 0.1.4-RC1 (2020/01/30)

* AnonAddy 0.1.4

## 0.1.3-RC2 (2020/01/24)

* Move Nginx temp folders to `/tmp`

## 0.1.3-RC1 (2020/01/19)

* AnonAddy 0.1.3

## 0.1.0-RC6 (2019/12/27)

* Postfix as sidecar container (#8)
* Use production env (#7)
* Add APP_NAME env var (#6)

## 0.1.0-RC5 (2019/12/24)

* Add sidecar cron service for scheduled tasks

## 0.1.0-RC4 (2019/12/23)

* Fix trusted proxies (#1)

## 0.1.0-RC3 (2019/12/23)

* Use sendmail (#5)

## 0.1.0-RC2 (2019/12/23)

* Fix `myhostname` postfix config

## 0.1.0-RC1 (2019/12/23)

* AnonAddy 0.1.0
* Log postfix to stdout (#4)
* Fix postfix config

## 0.0.0-bd78841-RC2 (2019/12/18)

* Fix anonaddy/anonaddy#13

## 0.0.0-bd78841-RC1 (2019/12/15)

* Initial version based on AnonAddy anonaddy/anonaddy@bd78841
