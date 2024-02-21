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
    echo "https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N51W132.SRTMSWBD.raw.zip"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N51W132.SRTMSWBD.raw.zip -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N51W132.SRTMSWBD.raw.zip | tail -1)
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
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N51W132.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N51W131.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N51W176.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N51W177.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N51W178.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N51W179.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N51W180.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W174.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W172.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W132.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W170.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W133.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W130.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W173.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W176.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W177.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N53W170.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N53W168.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N53W134.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N53W133.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N53W167.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N53W130.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N53W132.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W134.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W133.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W160.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W132.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W162.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W163.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W167.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W164.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W166.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W130.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W130.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W131.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W135.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W132.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W134.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W133.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W156.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W161.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W164.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W162.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W163.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W160.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W159.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N55W157.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W158.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W135.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W136.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W159.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W134.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W133.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W130.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W131.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W154.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W132.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W160.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W139.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W136.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W152.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W137.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W153.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W133.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W138.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W134.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W135.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W157.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W154.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W158.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W163.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W155.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W155.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W162.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W160.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W156.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W159.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N58W161.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W139.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W150.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W153.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W147.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W140.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W136.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W149.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W145.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W151.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W141.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W135.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W137.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W154.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W142.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W138.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W152.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W144.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W148.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W156.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W163.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W157.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W160.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W159.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W165.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W164.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W158.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W161.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N59W162.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W157.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W155.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W161.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W132.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W153.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W136.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W162.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N56W170.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W155.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W133.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W134.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W135.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W158.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W159.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W156.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W170.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W154.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W157.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W171.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N57W137.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W131.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W169.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W171.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N52W175.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W131.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W165.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N53W169.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N53W131.SRTMSWBD.raw.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMSWBD.003/2000.02.11/N54W161.SRTMSWBD.raw.zip
EDSCEOF