#!/usr/bin/env bash
# Adapted from https://gist.github.com/Adron/90863e51c8c5c0ad2049890bcd8abbfb

cd ~

terraform_version="0.11.11"

# Get URLs for most recent versions
terraform_url=$(curl https://releases.hashicorp.com/index.json | jq -r "{terraform}.terraform.versions.\"${terraform_version}\".builds[] | select(.os == \"linux\" and .arch == \"amd64\").url")
cd
mkdir terraform && cd $_

# Download Terraform. URI: https://www.terraform.io/downloads.html
echo "Downloading $terraform_url."
curl -o terraform.zip $terraform_url
# Unzip and install
unzip terraform.zip

echo '
  # Terraform Path
  export PATH=~/terraform/:$PATH
  ' >>$BASH_ENV
