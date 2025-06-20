#!/bin/bash

set -e

GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

echo -e "${GREEN}[+] Updating system and installing dependencies...${RESET}"
sudo apt update && sudo apt upgrade -y
# 'nikto' has been removed from this line
sudo apt install -y git curl unzip wget jq python3 python3-pip build-essential libpcap-dev libffi-dev libssl-dev cargo

echo -e "${GREEN}[+] Removing any existing Go installation...${RESET}"
sudo rm -rf /usr/local/go

echo -e "${GREEN}[+] Installing Go...${RESET}"
wget -q https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz
rm go1.24.4.linux-amd64.tar.gz

# Setup Go env
if ! grep -q 'export PATH=$PATH:/usr/local/go/bin' ~/.bashrc; then
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
    echo "export GOPATH=\$HOME/go" >> ~/.bashrc
    echo "export PATH=\$PATH:\$GOPATH/bin" >> ~/.bashrc
fi
source ~/.bashrc
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

echo -e "${GREEN}[+] Go version: $(go version)${RESET}"

# --- Tool Installation ---

# Go-based tools
declare -A TOOLS
TOOLS=(
    ["subfinder"]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    ["httpx"]="go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
    ["assetfinder"]="go install -v github.com/tomnomnom/assetfinder@latest"
    ["amass"]="go install -v github.com/owasp-amass/amass/v4/...@master"
    ["naabu"]="go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    ["nuclei"]="go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    ["waybackurls"]="go install -v github.com/tomnomnom/waybackurls@latest"
    ["gau"]="go install -v github.com/lc/gau/v2/cmd/gau@latest"
    ["gf"]="go install -v github.com/tomnomnom/gf@latest"
    ["hakrawler"]="go install -v github.com/hakluke/hakrawler@latest"
    ["dnsx"]="go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    ["katana"]="go install -v github.com/projectdiscovery/katana/cmd/katana@latest"
    ["gospider"]="go install -v github.com/jaeles-project/gospider@latest"
    ["urlfinder"]="go install -v github.com/ameenmaali/urlfinder@latest"
    ["waymore"]="go install -v github.com/xnl-h4ck3r/waymore@latest"
    ["anew"]="go install -v github.com/tomnomnom/anew@latest"
    ["subzy"]="go install -v github.com/LukaSikic/subzy@latest"
    ["dnstake"]="go install -v github.com/pwnesia/dnstake/cmd/dnstake@latest"
    ["puredns"]="go install -v github.com/d3mondev/puredns/v2@latest"
    ["tlsx"]="go install -v github.com/projectdiscovery/tlsx/cmd/tlsx@latest"
    ["crt"]="go install -v github.com/cemulus/crt@latest"
    ["bbot"]="go install -v github.com/blacklanternsecurity/bbot@latest"
    ["github-subdomains"]="go install -v github.com/gwen001/github-subdomains@latest"
    ["ffuf"]="go install -v github.com/ffuf/ffuf/v2@latest"
    ["gobuster"]="go install -v github.com/OJ/gobuster/v3/cmd/gobuster@latest"
    # 'kiterunner' has been removed
    ["gitleaks"]="go install -v github.com/gitleakst/gitleaks/v8@latest"
)

# Pip-based tools ('wfuzz' has been removed)
declare -A TOOLS_PIP
TOOLS_PIP=(
)

# Git clone tools
declare -A TOOLS_GIT
TOOLS_GIT=(
    ["dirsearch"]="https://github.com/maurosoria/dirsearch.git"
    ["S3Scanner"]="https://github.com/sa7mon/S3Scanner.git"
    ["hakip2host"]="https://github.com/hakluke/hakip2host.git"
    ["VhostFinder"]="https://github.com/s0md3v/VhostFinder.git"
    ["github-endpoints"]="https://github.com/gwen001/github-endpoints.git"
    ["subjs"]="https://github.com/lc/subjs.git"
    ["JSA"]="https://github.com/w9w/JSA.git"
    ["xnLinkFinder"]="https://github.com/xnl-h4ck3r/xnLinkFinder.git"
    ["getjswords"]="https://github.com/003random/getJSwords.git"
    ["mantra"]="https://github.com/Abhi-M/getmantra.git"
    ["SQLMap"]="https://github.com/sqlmapproject/sqlmap.git"
    ["ghauri"]="https://github.com/r0oth3x49/ghauri.git"
    ["commix"]="https://github.com/commixproject/commix.git"
    ["Web-Cache-Vulnerability-Scanner"]="https://github.com/Hackmanit/Web-Cache-Vulnerability-Scanner.git"
    ["SwaggerSpy"]="https://github.com/0xZDH/SwaggerSpy.git"
    ["theHarvester"]="https://github.com/laramies/theHarvester.git"
    ["Sublist3r"]="https://github.com/aboul3la/Sublist3r.git"
    ["EyeWitness"]="https://github.com/RedSiege/EyeWitness.git"
    ["LinkFinder"]="https://github.com/GerbenJavado/LinkFinder.git"
    ["truffleHog"]="https://github.com/trufflesecurity/truffleHog.git"
    ["Arjun"]="https://github.com/s0md3v/Arjun.git"
    # 'knockpy' has been removed
)

echo -e "${GREEN}[+] Installing Go-based tools...${RESET}"
for tool in "${!TOOLS[@]}"; do
    echo -e "${GREEN}[+] Installing $tool...${RESET}"
    if ! eval "${TOOLS[$tool]}"; then
        echo -e "${RED}[-] Failed to install $tool${RESET}"
    fi
done

if [ ${#TOOLS_PIP[@]} -ne 0 ]; then
    echo -e "${GREEN}[+] Installing Pip-based tools...${RESET}"
    for tool in "${!TOOLS_PIP[@]}"; do
        echo -e "${GREEN}[+] Installing $tool...${RESET}"
        if ! sudo pip3 install "${TOOLS_PIP[$tool]}"; then
            echo -e "${RED}[-] Failed to install $tool${RESET}"
        fi
    done
fi

mkdir -p ~/tools
cd ~/tools || exit

echo -e "${GREEN}[+] Cloning Git-based tools...${RESET}"
for tool in "${!TOOLS_GIT[@]}"; do
    if [ ! -d "$tool" ]; then
        echo -e "${GREEN}[+] Cloning $tool...${RESET}"
        if ! git clone "${TOOLS_GIT[$tool]}" "$tool"; then
            echo -e "${RED}[-] Failed to clone $tool${RESET}"
        fi
    fi
done

echo -e "${GREEN}[+] Installing dependencies for Git-based tools...${RESET}"
# Dependency installation lines for the removed tools are now gone
(cd ~/tools/theHarvester && sudo pip3 install -r requirements.txt)
(cd ~/tools/Sublist3r && sudo pip3 install -r requirements.txt)
(cd ~/tools/LinkFinder && sudo pip3 install -r requirements.txt)
(cd ~/tools/truffleHog && sudo pip3 install -r requirements.txt)
(cd ~/tools/Arjun && sudo python3 setup.py install)
(cd ~/tools/EyeWitness/Python/setup && sudo ./setup.sh)


# GF Patterns setup
echo -e "${GREEN}[+] Setting up GF patterns...${RESET}"
mkdir -p ~/.gf
if [ ! -d ~/.gf-patterns ]; then
    git clone https://github.com/1ndianl33t/Gf-Patterns.git ~/.gf-patterns
fi
cp -f ~/.gf-patterns/*.json ~/.gf/ 2>/dev/null || true

# 'SecLists' setup has been removed

# Final check
echo -e "${GREEN}\n[+] Verifying tool installation...${RESET}"
MISSING=()

# ... (rest of the verification script remains the same) ...

echo -e "${GREEN}[+] All tools installed successfully! Happy hunting!${RESET}"
