#!/usr/bin/env bash
# Adapted from https://gist.github.com/Adron/90863e51c8c5c0ad2049890bcd8abbfb

cd ~

# Get URLs for most recent versions
terraform_url=$(curl https://releases.hashicorp.com/index.json | jq '{terraform}' | egrep "linux.*amd64" | sort --version-sort -r | head -1 | awk -F[\"] '{print $4}')
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
