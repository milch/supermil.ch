fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
### build
```
fastlane build
```
Rebuild the static HTML
### infra
```
fastlane infra
```
Build the required infrastructure on AWS using terraform
### ssl
```
fastlane ssl
```
Renew SSL certificates with certbot
### upload
```
fastlane upload
```

### invalidate_cache
```
fastlane invalidate_cache
```
Create a Cloudfront invalidation for the distribution
### publish_site
```
fastlane publish_site
```
Publish a new version of the website

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
