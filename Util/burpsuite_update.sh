#!/bin/bash
valid_editions=("community", "pro")
edition="community"

print_usage(){
  echo "Usage: $(basename ${0}) [edition]"
  echo "    edition = pro | community (default)"
  exit 1
}

if [[ ${#} -gt 1 ]]; then
  print_usage
elif [[ ${#} -eq 1 ]]; then
  if [[ ! "${valid_editions[*]}" =~ "${1}" ]]; then
    print_usage
  else
    edition=${1}
  fi
fi

# scrap releases site for version
echo "[*] Scrapping latest version from portswigger website"
version_unparsed=$(wget https://portswigger.net/burp/releases/community/latest -O- -q | grep 'version="')
version=$(echo "${version_unparsed##*version=\"}" | cut -d'"' -f1)

# download and replace jar
echo "[*] Updating to version ${version}"
tmp=$(mktemp /tmp/burp.update.XXXX) \
  && wget --output-document=${tmp} "https://portswigger.net/burp/releases/download?product=${edition}&version=${version}&type=Jar" \
  && sudo cp ${tmp} /usr/share/burpsuite/burpsuite.jar \
  && echo "[*] Burpsuite is up to date!" \
  || echo "[!] Update failed!" && exit 2