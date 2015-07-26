# curl-chk – checksum wrapper for curl

curl_chk is a wrapper for curl that verifies the content
of the actual files that were downloaded via their md5 sums.

[![Build Status](https://travis-ci.org/JosuaKrause/curl-chk.svg?branch=master)](https://travis-ci.org/JosuaKrause/curl-chk)

The md5 sum can either be passed as part of the URL or explicitely as
argument `--md5`. All other arguments are used as is and as specified by curl.
The results of the integrity check are printed to *stderr* in the format:

```
./index.html: OK 09b9c392dc1f6e914cea287cb6be34b0
./foo.txt: FAILED d8e8fca2dc0f896fd7cb4cb0031ba249
WARNING: 1 of 2 computed checksums did NOT match
```

The warning line only appears if at least one of the checks failed.

Example calls:
```bash
./curl "http://example.com/#md5=09b9c392dc1f6e914cea287cb6be34b0" -o "index.html"
./curl --md5 09b9c392dc1f6e914cea287cb6be34b0 -o "index.html" "http://example.com/"
./curl -O "http://example.com/index.html#md5=09b9c392dc1f6e914cea287cb6be34b0"
./curl "http://example.com/#md5=09b9c392dc1f6e914cea287cb6be34b0"
```

Note that if an output parameter is omitted the fetched content will be printed
to STD_OUT iff the verification was successful. This allows for a secure version
of the rather common pattern of piping a downloaded script to `sh`:

```bash
./curl "http://fancytool.com/installer#md5=09b9c392dc1f6e914cea287cb6be34b0 | sh"
```

You can use the wrapper either directly or by renaming
the original, changing `REAL_CURL` in the script, and
moving the script into path.

Pull requests are highly appreciated!
