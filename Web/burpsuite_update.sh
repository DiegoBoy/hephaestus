if [[ ${#} -ne 1 ]]; then
  echo "Usage: $(basename ${0}) <version>"
  exit 1
fi

# scrap releases site for version 
version_unparsed=$(wget https://portswigger.net/burp/releases/community/latest -O- -q | grep 'version="')
version=$(echo "${version_unparsed##*version=\"}" | cut -d'"' -f1)

# replace jar
rm /usr/share/burpsuite/burpsuite.jar
wget https://portswigger.net/burp/releases/download?product=community&version=${version}&type=Jar -O /usr/share/burpsuite/burpsuite.jar