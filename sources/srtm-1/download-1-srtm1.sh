#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (wlbragg): " username
    username=${username:-wlbragg}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W118.SRTMGL1.hgt.zip"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W118.SRTMGL1.hgt.zip -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W118.SRTMGL1.hgt.zip | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N48W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W123.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N45W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W121.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W120.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W123.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W121.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W121.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W123.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W122.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W124.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W125.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W122.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W124.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W123.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W120.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W120.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W122.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W124.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N49W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W120.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W123.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W122.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W121.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W124.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W120.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N46W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N47W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W120.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W123.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W120.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W123.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W120.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W117.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W121.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W120.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W121.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W120.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W122.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W121.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W124.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N49W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N48W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N45W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W122.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N45W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N47W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W121.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N49W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W122.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W124.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W122.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N46W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N46W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N47W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W121.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W121.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N46W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N48W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W125.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N48W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W125.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N45W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N49W114.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W125.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N48W115.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N46W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N49W118.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W119.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N45W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N47W116.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N47W114.SRTMGL1.hgt.zip
EDSCEOF