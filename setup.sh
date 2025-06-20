#!/bin/bash

set -e

GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

echo -e "${GREEN}[+] Updating system...${RESET}"
sudo apt update && sudo apt upgrade -y

echo -e "${GREEN}[+] Installing required dependencies...${RESET}"
sudo apt install -y git curl unzip wget jq python3 python3-pip build-essential libpcap-dev libffi-dev libssl-dev cargo

echo -e "${GREEN}[+] Removing any existing Go installation...${RESET}"
sudo rm -rf /usr/local/go

echo -e "${GREEN}[+] Installing Go 1.24.4...${RESET}"
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

# Declare tools and commands
declare -A TOOLS

# Go install tools
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
    # The original 'crt' repository seems to be a different tool. 'cemulus/crt' is for certificate transparency.
    ["crt"]="go install -v github.com/cemulus/crt@latest"
    ["bbot"]="go install -v github.com/blacklanternsecurity/bbot@latest"
    ["github-subdomains"]="go install -v github.com/gwen001/github-subdomains@latest"
    ["ffuf"]="go install -v github.com/ffuf/ffuf/v2@latest"
)

# Git clone or python/pip install tools
declare -A TOOLS_GIT
TOOLS_GIT=(
    ["dirsearch"]="git clone https://github.com/maurosoria/dirsearch.git"
    ["S3Scanner"]="git clone https://github.com/sa7mon/S3Scanner.git"
    # The original CloudHunter repository is no longer available. bbot (already in Go tools) is a good, modern alternative.
    ["hakip2host"]="git clone https://github.com/hakluke/hakip2host.git"
    ["VhostFinder"]="git clone https://github.com/s0md3v/VhostFinder.git"
    ["github-endpoints"]="git clone https://github.com/gwen001/github-endpoints.git"
    ["subjs"]="git clone https://github.com/lc/subjs.git"
    # The original JSA repository is no longer available. This is a fork.
    ["JSA"]="git clone https://github.com/w9w/JSA.git"
    ["xnLinkFinder"]="git clone https://github.com/xnl-h4ck3r/xnLinkFinder.git"
    ["getjswords"]="git clone https://github.com/003random/getJSwords.git"
    # The original mantra repository is unavailable. This is an archived version of OWASP Mantra.
    ["mantra"]="git clone https://github.com/Abhi-M/getmantra.git"
    ["SQLMap"]="git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git"
    ["ghauri"]="git clone https://github.com/r0oth3x49/ghauri.git"
    ["commix"]="git clone https://github.com/commixproject/commix.git"
    ["Web-Cache-Vulnerability-Scanner"]="git clone https://github.com/Hackmanit/Web-Cache-Vulnerability-Scanner.git"
    ["SwaggerSpy"]="git clone https://github.com/0xZDH/SwaggerSpy.git"
)

echo -e "${GREEN}[+] Installing Go-based tools...${RESET}"
for tool in "${!TOOLS[@]}"; do
    echo -e "${GREEN}[+] Installing $tool...${RESET}"
    if ! eval "${TOOLS[$tool]}"; then
        echo -e "${RED}[-] Failed to install $tool${RESET}"
    fi
done

echo -e "${GREEN}[+] Cloning Git-based tools...${RESET}"
mkdir -p ~/tools
cd ~/tools || exit

for tool in "${!TOOLS_GIT[@]}"; do
    if [ ! -d "$tool" ]; then
        echo -e "${GREEN}[+] Cloning $tool...${RESET}"
        if ! eval "${TOOLS_GIT[$tool]}"; then
            echo -e "${RED}[-] Failed to clone $tool${RESET}"
        fi
    fi
done

# GF Patterns setup
echo -e "${GREEN}[+] Setting up GF patterns...${RESET}"
mkdir -p ~/.gf
if [ ! -d ~/.gf-patterns ]; then
    git clone https://github.com/1ndianl33t/Gf-Patterns.git ~/.gf-patterns
fi
cp ~/.gf-patterns/*.json ~/.gf/ 2>/dev/null || true

# Final check
echo -e "${GREEN}\n[+] Verifying tool installation...${RESET}"
MISSING=()

for tool in "${!TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING+=("$tool")
    fi
done

echo -e "${GREEN}\n[+] Tools installed in ~/tools:${RESET}"
for tool in "${!TOOLS_GIT[@]}"; do
    if [ ! -d "$HOME/tools/$tool" ]; then
        MISSING+=("$tool (git)")
    fi
done

if [ "${#MISSING[@]}" -eq 0 ]; then
    echo -e "${GREEN}[+] All tools installed successfully!${RESET}"
else
    echo -e "${RED}[-] The following tools failed to install or are missing:${RESET}"
    for m in "${MISSING[@]}"; do
        echo -e "${RED} - $m${RESET}"
    done
    echo -e "${RED}[!] Please try to install them manually.${RESET}"
fi
