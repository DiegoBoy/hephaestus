#!/bin/bash
valid_editions=("community", "professional")
edition="community"

if [[ ${#} -gt 1 ]] ||
   [[ ${#} -eq 1 ]] && 
   [[ ! "${valid_editions[*]}" =~ "${1}" ]]; then
  echo "Usage: $(basename ${0}) [edition]"
  echo "    edition = professional | community (default)"
  exit 1
fi

# scrap releases site for version
echo "Scrapping latest version from portswigger website"
version_unparsed=$(wget https://portswigger.net/burp/releases/community/latest -O- -q | grep 'version="')
version=$(echo "${version_unparsed##*version=\"}" | cut -d'"' -f1)

# download and replace jar
echo "Updating to version ${version}"
tmp=$(mktemp /tmp/burp.XXXX) \
  && wget --output-document=${tmp} "https://portswigger.net/burp/releases/download?product=${edition}&version=${version}&type=Jar" \
  && sudo mv ${tmp} /usr/share/burpsuite/burpsuite.jar \
  && echo "Burpsuite is up to date!" \
  || echo "Update failed!" && exit 2