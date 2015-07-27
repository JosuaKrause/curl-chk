# curl-chk – checksum wrapper for curl

curl_chk is a wrapper for curl that verifies the content
of the actual files that were downloaded via their checksums.
The `md5` checksum is guaranteed to be supported.
If python is installed on the system `md5`, `sha1`, `sha224`, `sha256`, `sha384`,
and `sha512` are also guaranteed to be supported but there might be more
supported methods (you can list all available methods via `./curl --digest-list`).

[![Build Status](https://travis-ci.org/JosuaKrause/curl-chk.svg?branch=master)](https://travis-ci.org/JosuaKrause/curl-chk)

The checksum can either be passed as part of the URL or explicitely as
argument `--digest`. All other arguments are used as is and as specified by curl.
The results of the integrity check are printed to *stderr* in the format:

```
./index.html: OK 09b9c392dc1f6e914cea287cb6be34b0
./foo.txt: FAILED d8e8fca2dc0f896fd7cb4cb0031ba249
WARNING: 1 of 2 computed checksums did NOT match
```

The shown checksums are the actual checksums of the downloaded files.
The warning line only appears if at least one of the checks failed.

Example calls:
```bash
./curl "http://example.com/#md5=09b9c392dc1f6e914cea287cb6be34b0" -o "index.html"
./curl --digest "sha1=0e973b59f476007fd10f87f347c3956065516fc0" -o "index.html" "http://example.com/"
./curl -O "http://example.com/index.html#md5=09b9c392dc1f6e914cea287cb6be34b0"
./curl "http://example.com/#md5=09b9c392dc1f6e914cea287cb6be34b0"
```

Note that if an output parameter is omitted the fetched content will be printed
to *stdout* iff the verification was successful. This allows for a secure version
of the rather common pattern of piping a downloaded script to `sh`:

```bash
./curl "http://fancytool.com/installer#md5=e17f840d197c47df3e6d5b3bc4ca4ff4" | sh
```

If a digest method does not exist the file is downloaded as if no digest was
suggested. However, if the digest was specified using `--digest` the file will
not be downloaded and an error will be emitted.

You can use the wrapper either directly or by renaming the original, setting
the environment variable `REAL_CURL` to the new path, and
moving the script into `PATH`.

Pull requests are highly appreciated!
