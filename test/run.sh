#!/bin/bash

cd "$(dirname $0)"

TEST_DIR="./out"
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
  local ret=1
  echo "NOTICE: $@"
  if [ "${err}" == "-" ]; then
    "$@"
    ret=$?
  else
    "$@" 2> "${err}"
    ret=$?
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

num_tests=0
begin_test() {
  num_tests=$((num_tests+1))
  echo "NOTICE: running test ${num_tests}"
}

md5_a="d8e8fca2dc0f896fd7cb4cb0031ba249"
md5_b="95b3644556b48a25f3366d82b0e3b349"

## using explicit --md5
# correct verification
begin_test
run "${STD_ERR}" ../curl -# -o "${TEST_DIR}/a.tmp" --md5 "${md5_a}" "${GITHUB_PREFIX}/a.test"
check_exit $? 0
check_file "a.test" "${TEST_DIR}/a.tmp"
run "-" cat "${STD_ERR}"
run "-" grep -q "${TEST_DIR}/a.tmp: OK ${md5_a}" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

# wrong md5 sum
begin_test
run "${STD_ERR}" ../curl -# -o "${TEST_DIR}/b.tmp" --md5 "${md5_a}" "${GITHUB_PREFIX}/b.test"
check_exit $? 42
check_file "b.test" "${TEST_DIR}/b.tmp"
run "-" cat "${STD_ERR}"
run "-" grep -q "${TEST_DIR}/b.tmp: FAILED ${md5_a}" "${STD_ERR}"
check_exit $? 0
run "-" grep -q "WARNING: 1 of 1 computed checksums did NOT match" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

## using URL fragment
# correct verification
begin_test
run "${STD_ERR}" ../curl -# -o "${TEST_DIR}/b.tmp" --url "${GITHUB_PREFIX}/b.test#md5=${md5_b}"
check_exit $? 0
check_file "b.test" "${TEST_DIR}/b.tmp"
run "-" cat "${STD_ERR}"
run "-" grep -q "${TEST_DIR}/b.tmp: OK ${md5_b}" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

# wrong md5 sum
begin_test
run "${STD_ERR}" ../curl -# -o "${TEST_DIR}/a.tmp" --url "${GITHUB_PREFIX}/a.test#md5=${md5_b}"
check_exit $? 42
check_file "a.test" "${TEST_DIR}/a.tmp"
run "-" cat "${STD_ERR}"
run "-" grep -q "${TEST_DIR}/a.tmp: FAILED ${md5_b}" "${STD_ERR}"
check_exit $? 0
run "-" grep -q "WARNING: 1 of 1 computed checksums did NOT match" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

## auto inference
# correct verification - multiple files
begin_test
cd "${TEST_DIR}"
run "../${STD_ERR}" ../../curl -# --remote-name-all "${GITHUB_PREFIX}/a.test#md5=${md5_a}" "${GITHUB_PREFIX}/b.test?md5=${md5_b}"
x=$?
cd ".."
check_exit $x 0
check_file "a.test" "${TEST_DIR}/a.test#md5=${md5_a}"
check_file "b.test" "${TEST_DIR}/b.test?md5=${md5_b}"
run "-" cat "${STD_ERR}"
run "-" grep -q "a.test#md5=${md5_a}: OK ${md5_a}" "${STD_ERR}"
check_exit $? 0
run "-" grep -q "b.test?md5=${md5_b}: OK ${md5_b}" "${STD_ERR}"
check_exit $? 0
rm -- "${STD_ERR}"

echo "NOTICE: cleaning up"
rm -r -- "${TEST_DIR}"

echo "NOTICE: all tests were successful!"
exit 0
