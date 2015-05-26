# curl_chk – checksum wrapper for curl

curl_chk is a wrapper for curl that verifies the content
of the actual file that was downloaded via its md5 sum.

[![Build Status](https://travis-ci.org/JosuaKrause/curl_chk.svg?branch=master)](https://travis-ci.org/JosuaKrause/curl_chk)

Currently only one file at a time is allowed. The local
name of this file has to be specified via `-o` and the
md5 sum can either be passed as part of the URL (only
if the URL was specified via `--url`) or explicitely as
argument of curl `--md5`. All other arguments are used
as is and as specified by curl.

Example calls:
```
./curl --url "http://example.com/#md5=09b9c392dc1f6e914cea287cb6be34b0" -o "index.html"
./curl --md5 09b9c392dc1f6e914cea287cb6be34b0 -o "index.html" "http://example.com/"
```

You can use the wrapper either directly or by renaming
the original, changing `REAL_CURL` in the script, and
moving the script into path.

Pull requests are highly appreciated!
