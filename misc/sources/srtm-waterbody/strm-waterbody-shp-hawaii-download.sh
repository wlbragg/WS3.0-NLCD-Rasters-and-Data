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
    echo "https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N18W156.SRTMSWBD.raw.zip"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N18W156.SRTMSWBD.raw.zip -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N18W156.SRTMSWBD.raw.zip | tail -1)
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
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N18W156.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N19W155.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N19W156.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N19W157.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N20W157.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N20W156.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N20W158.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N21W160.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N21W157.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N21W161.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N21W158.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N21W159.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N22W160.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N22W161.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N23W167.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N23W165.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N23W162.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N24W168.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N25W168.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N25W172.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N26W174.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N27W176.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N28W178.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N28W179.SRTMSWBD.raw.zip
EDSCEOF