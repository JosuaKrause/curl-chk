#!/bin/bash

cd "$(dirname $0)"

TEST_DIR="./out"
STD_OUT="${TEST_DIR}/out.tmp"
GITHUB_USER="JosuaKrause"
GITHUB_REPO="curl_chk"
GITHUB_BRANCH="master"
GITHUB_PREFIX="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/test"

echo "running tests.."
echo "the github prefix is: ${GITHUB_PREFIX}"

if [ ! -d "${TEST_DIR}" ]; then
  mkdir -p "${TEST_DIR}"
fi

check_exit() {
  if [ -f "${STD_OUT}" ]; then
    cat "${STD_OUT}"
  fi
  if [ $1 != $2 ]; then
    echo "^ unexpected exit status! expected $2 got $1 ^"
    exit 1
  fi
}

check_file() {
  diff -q "$1" "$2"
  if [ $? -ne 0 ]; then
    diff -u "$1" "$2"
    print "^ $2 doesn't match $1 ^"
    exit 2
  fi
}

num_tests=0
begin_test() {
  ((num_tests++))
  echo "test ${num_tests}"
}

md5_a="d8e8fca2dc0f896fd7cb4cb0031ba249"
md5_b="95b3644556b48a25f3366d82b0e3b349"

## using explicit --md5
# correct verification
begin_test
../curl -# -o "${TEST_DIR}/a.tmp" --md5 "${md5_a}" "${GITHUB_PREFIX}/a.test" > "${STD_OUT}"
check_exit $? 0
check_file "a.test" "${TEST_DIR}/a.tmp"
grep -q "md5: '${md5_a}'" "${STD_OUT}"
x=$?
rm -- "${STD_OUT}"
check_exit $x 0

# wrong md5 sum
begin_test
../curl -# -o "${TEST_DIR}/b.tmp" --md5 "${md5_a}" "${GITHUB_PREFIX}/b.test"
check_exit $? 69
check_file "b.test" "${TEST_DIR}/b.tmp"

## using URL fragment
# correct verification
begin_test
../curl -# -o "${TEST_DIR}/b.tmp" --url "${GITHUB_PREFIX}/b.test#md5=${md5_b}" > "${STD_OUT}"
check_exit $? 0
check_file "b.test" "${TEST_DIR}/b.tmp"
grep -q "md5: '${md5_b}'" "${STD_OUT}"
x=$?
rm -- "${STD_OUT}"
check_exit $x 0

# wrong md5 sum
begin_test
../curl -# -o "${TEST_DIR}/a.tmp" --url "${GITHUB_PREFIX}/a.test#md5=${md5_b}"
check_exit $? 69
check_file "a.test" "${TEST_DIR}/a.tmp"

echo "cleaning up"
rm -r -- "${TEST_DIR}"

echo "all tests were successful!"
exit 0
