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
    echo "https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N23W084.SRTMGL1.hgt.zip"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N23W084.SRTMGL1.hgt.zip -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N23W084.SRTMGL1.hgt.zip | tail -1)
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
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N23W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N24W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N26W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N29W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N26W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N29W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N27W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N25W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N24W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N28W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N45W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N25W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W075.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N27W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N31W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W085.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W086.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N25W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W085.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N31W086.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N30W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N27W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N28W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N29W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N30W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N31W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W074.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N31W085.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W085.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N24W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N29W085.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W085.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W074.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N24W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W075.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N26W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N30W086.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N26W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W085.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W077.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N28W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W086.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N30W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W085.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N39W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N35W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N29W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N31W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N34W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N29W086.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N33W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N38W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N30W085.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N31W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N32W084.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W083.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N36W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N37W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W074.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W074.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W075.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N45W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N45W074.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W082.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W075.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W075.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W075.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W074.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W078.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N45W075.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W081.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W080.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N44W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N41W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W075.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N43W079.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N40W076.SRTMGL1.hgt.zip
https://e4ftl01.cr.usgs.gov//DP109/SRTM/SRTMGL1.003/2000.02.11/N42W078.SRTMGL1.hgt.zip
EDSCEOF