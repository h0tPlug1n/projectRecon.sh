#!/bin/bash

# Basic Sanity
mkdir scan-$(date +"%d-%m-%y")
cd scan-$(date +"%d-%m-%y")/

# Subdomain Enumeration
subfinder -dL ../domains.txt -nc -all -recursive -silent -o subfinder.txt
cat ../domains.txt | xargs -n 1 assetfinder -subs-only | grep -e "[*].*" -v | anew assetfinder.txt
cat subfinder.txt assetfinder.txt | anew subdomains.txt
rm subfinder.txt assetfinder.txt

# DNS Recon (Records and Zone Transfers)
cat subdomains.txt | dnx -a -aaaa -cname -ns -txt -srv -ptr -mx -soa -axfr -caa -json -o output.json

# Port Scanning
sudo nmap -iL subdomains.txt -p- -sS -sC -sV -O -f -mtu 32 --script="not intrusive" --version-all --version-intensity 9 --osscan-guess --max-os-tries 5 --max-retries 3 --min-rate 100 --max-rate -oN nmap.txt 

# Tech Stack Detection
httpx-toolkit -l subdomains.txt -td -o tech_detect.txt

# HTTP Recon (HTTP Response Code,  HTTP Response Verb, HTTP Title, Screenshots)
httpx-toolkit -l subdomains.txt -status-code -content-length -web-server -content-type -response-time -title -method -json -o http.json
input_file="http.json"
output_file="https.json"
{
	echo "["
	sed 's/$/,/' "$input_file"
	sed -i '$ s/,$//' "$output_file"
	echo "]"
} > "$output_file"

# Directory Listing
dirsearch -l subdomains.txt -t 100 --max-rate=10 -x 429 -r -R 10 --crawl --full-url --format=json -o dirlist.json -e conf,config,bak,backup,swp,old,db,sql,asp,aspx,aspx~,asp~,py,py~,rb,rb~,php,php~,bak,bkp,cache,cgi,conf,csv,html,inc,jar,js,json,jsp,jsp,lock,log,rar,old,sql,sql.gz,http://sql.zip,sql.tar.gz,sql~,swp,swp~,tar,tar.bz2,tar.gz,txt,wadl,zip,.log,.xml,.js,.json

# Whois Scan
while read -r line; do whois "$line" < subdomains.txt | tee whois_report.txt
