#!/bin/bash
# -*- coding: utf-8 -*-
# Copyright (c) 2015 Josua Krause

cd "$(dirname $0)"

TEST_DIR="./out"
STD_OUT="${TEST_DIR}/out.tmp"
STD_ERR="${TEST_DIR}/err.tmp"
GITHUB_USER="JosuaKrause"
GITHUB_REPO="curl_chk"
GITHUB_BRANCH="master"
GITHUB_PREFIX="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/test"

echo "NOTICE: running tests.."
echo "NOTICE: the github prefix is: ${GITHUB_PREFIX}"

if [ ! -d "${TEST_DIR}" ]; then
  mkdir -p "${TEST_DIR}"
fi

run() {
  local err="$1"; shift
  local out="$1"; shift
  local ret=1
  echo "NOTICE: $@"
  if [ "${out}" == "-" ]; then
    if [ "${err}" == "-" ]; then
      "$@"
      ret=$?
    else
      "$@" 2> "${err}"
      ret=$?
    fi
  else
    if [ "${err}" == "-" ]; then
      "$@" 1> "${out}"
      ret=$?
    else
      "$@" 1> "${out}" 2> "${err}"
      ret=$?
    fi
    cat "${out}"
  fi
  return $ret
}

check_exit() {
  if [ $1 != $2 ]; then
    if [ -f "${STD_ERR}" ]; then
      cat "${STD_ERR}"
    fi
    echo "^ unexpected exit status! expected $2 got $1 ^"
    exit 1
  fi
}

check_file() {
  diff -q "$1" "$2"
  if [ $? -ne 0 ]; then
    diff -u "$1" "$2"
    echo "^ $2 doesn't match $1 ^"
    exit 2
  fi
}

no_file() {
  echo "NOTICE: expect $1 to not exist"
  if [ -f "$1" ]; then
    echo "$1 exists. It should not!"
    exit 3
  fi
}

num_tests=0
begin_test() {
  num_tests=$((num_tests+1))
  echo "NOTICE: running test ${num_tests}"
}

echo "no python: ${NO_PYTHON}"
echo "available digests:"
run "-" "-" ../curl --digest-list
check_exit $? 0

md5_a="d8e8fca2dc0f896fd7cb4cb0031ba249"
md5_b="95b3644556b48a25f3366d82b0e3b349"

## using explicit --digest
# correct verification
begin_test
run "${STD_ERR}" "-" ../curl -# -o "${TEST_DIR}/a.tmp" --digest "md5=${md5_a}" "${GITHUB_PREFIX}/a.test"
check_exit $? 0
check_file "a.test" "${TEST_DIR}/a.tmp"
run "-" "-" cat "${STD_ERR}"
run "-" "-" grep -q "${TEST_DIR}/a.tmp: OK ${md5_a}" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

# wrong md5 sum
begin_test
run "${STD_ERR}" "-" ../curl -# -o "${TEST_DIR}/b.tmp" --digest "md5=${md5_a}" "${GITHUB_PREFIX}/b.test"
check_exit $? 42
check_file "b.test" "${TEST_DIR}/b.tmp"
run "-" "-" cat "${STD_ERR}"
run "-" "-" grep -q "${TEST_DIR}/b.tmp: FAILED ${md5_b}" "${STD_ERR}"
check_exit $? 0
run "-" "-" grep -q "WARNING: 1 of 1 computed checksums did NOT match" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

## using URL fragment
# correct verification
begin_test
run "${STD_ERR}" "-" ../curl -# -o "${TEST_DIR}/b.tmp" --url "${GITHUB_PREFIX}/b.test#md5=${md5_b}"
check_exit $? 0
check_file "b.test" "${TEST_DIR}/b.tmp"
run "-" "-" cat "${STD_ERR}"
run "-" "-" grep -q "${TEST_DIR}/b.tmp: OK ${md5_b}" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

# wrong md5 sum
begin_test
run "${STD_ERR}" "-" ../curl -# -o "${TEST_DIR}/a.tmp" --url "${GITHUB_PREFIX}/a.test#md5=${md5_b}"
check_exit $? 42
check_file "a.test" "${TEST_DIR}/a.tmp"
run "-" "-" cat "${STD_ERR}"
run "-" "-" grep -q "${TEST_DIR}/a.tmp: FAILED ${md5_a}" "${STD_ERR}"
check_exit $? 0
run "-" "-" grep -q "WARNING: 1 of 1 computed checksums did NOT match" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

## auto inference
# correct verification - multiple files
begin_test
cd "${TEST_DIR}"
run "../${STD_ERR}" "-" ../../curl -# --remote-name-all "${GITHUB_PREFIX}/a.test#md5=${md5_a}" "${GITHUB_PREFIX}/b.test?md5=${md5_b}"
x=$?
cd ".."
check_exit $x 0
check_file "a.test" "${TEST_DIR}/a.test"
check_file "b.test" "${TEST_DIR}/b.test?md5=${md5_b}"
run "-" "-" cat "${STD_ERR}"
run "-" "-" grep -q "a.test: OK ${md5_a}" "${STD_ERR}"
check_exit $? 0
run "-" "-" grep -q "b.test?md5=${md5_b}: OK ${md5_b}" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

# partial verification - multiple files
begin_test
cd "${TEST_DIR}"
run "../${STD_ERR}" "-" ../../curl -# --remote-name-all "${GITHUB_PREFIX}/a.test#md5=${md5_a}" "${GITHUB_PREFIX}/b.test" --digest "md5=${md5_a}"
x=$?
cd ".."
check_exit $x 42
check_file "a.test" "${TEST_DIR}/a.test"
check_file "b.test" "${TEST_DIR}/b.test"
run "-" "-" cat "${STD_ERR}"
run "-" "-" grep -q "a.test: OK ${md5_a}" "${STD_ERR}"
check_exit $? 0
run "-" "-" grep -q "b.test: FAILED ${md5_b}" "${STD_ERR}"
check_exit $? 0
run "-" "-" grep -q "WARNING: 1 of 2 computed checksums did NOT match" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

## omitting output parameter
# correct verification
begin_test
run "${STD_ERR}" "${STD_OUT}" ../curl -# "${GITHUB_PREFIX}/a.test#md5=${md5_a}"
check_exit $? 0
check_file "a.test" "${STD_OUT}"
run "-" "-" cat "${STD_ERR}"
run "-" "-" grep -q "STDOUT: OK ${md5_a}" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"
rm -- "${STD_OUT}"

# wrong md5 sum
begin_test
run "${STD_ERR}" "${STD_OUT}" ../curl -# "${GITHUB_PREFIX}/b.test#md5=${md5_a}"
check_exit $? 42
check_file "/dev/null" "${STD_OUT}"
run "-" "-" cat "${STD_ERR}"
run "-" "-" grep -q "STDOUT: FAILED ${md5_b}" "${STD_ERR}"
check_exit $? 0
run "-" "-" grep -q "WARNING: 1 of 1 computed checksums did NOT match" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"
rm -- "${STD_OUT}"


sha1_a="4e1243bd22c66e76c2ba9eddc1f91394e57f9f83"
sha256_b="2056a28ea38a000f3a3328cb7fabe330638d3258affe1a869e3f92986222d997"
## multiple digests
# three different ones
begin_test
run "${STD_ERR}" "-" ../curl -# "${GITHUB_PREFIX}/a.test#sha1=${sha1_a}" -o "${TEST_DIR}/digest_a.tmp" "${GITHUB_PREFIX}/a.test?md5=${md5_a}" -o "${TEST_DIR}/digest_c.tmp" "${GITHUB_PREFIX}/b.test" --digest "sha256=${sha256_b}" -o "${TEST_DIR}/digest_b.tmp"
x=$?
if [ ! -z $NO_PYTHON ] && [ $NO_PYTHON != 0 ]; then
  check_exit $x 94
  run "-" "-" cat "${STD_ERR}"
  run "-" "-" grep -q "Unknown digest 'sha256'! Use '../curl --digest-list' for a list of available digests."
  no_file "${TEST_DIR}/digest_a.tmp"
  no_file "${TEST_DIR}/digest_b.tmp"
  no_file "${TEST_DIR}/digest_c.tmp"
else
  check_exit $x 0
  check_file "a.test" "${TEST_DIR}/digest_a.tmp"
  check_file "b.test" "${TEST_DIR}/digest_b.tmp"
  check_file "a.test" "${TEST_DIR}/digest_c.tmp"
  run "-" "-" cat "${STD_ERR}"
  run "-" "-" grep -q "${TEST_DIR}/digest_a.tmp: OK ${sha1_a}" "${STD_ERR}"
  check_exit $? 0
  run "-" "-" grep -q "${TEST_DIR}/digest_b.tmp: OK ${sha256_b}" "${STD_ERR}"
  check_exit $? 0
  run "-" "-" grep -q "${TEST_DIR}/digest_c.tmp: OK ${md5_a}" "${STD_ERR}"
  check_exit $? 0
  rm -- "${STD_ERR}"
fi

# invalid one
begin_test
run "${STD_ERR}" "-" ../curl -# "${GITHUB_PREFIX}/a.test#foo=${md5_a}" -o "${TEST_DIR}/foo_a.tmp"
check_exit $? 0
check_file "a.test" "${TEST_DIR}/foo_a.tmp"
run "-" "-" cat "${STD_ERR}"
run "${STD_ERR}" "-" ../curl -# "${GITHUB_PREFIX}/b.test" --digest "foo=${md5_b}" -o "${TEST_DIR}/foo_b.tmp"
check_exit $? 94
run "-" "-" cat "${STD_ERR}"
run "-" "-" grep -q "Unknown digest 'foo'! Use '../curl --digest-list' for a list of available digests." "${STD_ERR}"
no_file "${TEST_DIR}/foo_b.tmp"

echo "NOTICE: cleaning up"
rm -r -- "${TEST_DIR}"

echo "NOTICE: all tests were successful!"
exit 0
