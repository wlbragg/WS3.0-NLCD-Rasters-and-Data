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
    echo "https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W154.SRTMGL1.hgt.zip"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W154.SRTMGL1.hgt.zip -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W154.SRTMGL1.hgt.zip | tail -1)
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
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W154.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W160.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N57W154.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W158.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W164.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W158.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W150.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N57W158.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W144.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N56W160.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W160.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W154.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N55W160.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N56W158.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W148.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N56W154.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N56W159.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N55W156.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W155.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W152.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N56W162.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W151.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W155.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N56W161.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W161.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W157.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W159.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W159.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N57W153.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N55W161.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W162.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N56W155.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W163.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N56W157.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N57W159.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N57W155.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W165.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W162.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W153.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W156.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W153.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W161.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N57W156.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W156.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N55W159.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W145.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W163.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W149.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N57W157.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W152.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N55W157.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N58W157.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N59W147.SRTMGL1.hgt.zip
EDSCEOF