#!/usr/bin/env bash
set -e

export WP_PROXY_PREFIX=./dist

exiterr() {
	echo -e "✘ $*" 1>&2;
	exit 23
}

cleanup() {
  trap - SIGINT SIGTERM EXIT
  # script cleanup here
  rm -f dist/conf.d/*.vhost
}
trap cleanup SIGINT SIGTERM EXIT

test -x test/test.sh || exiterr "You must execute this test script from the root of the repo."

output=$(WP_PROXY_MAP_FILE=./test/ymls/valid.yml dist/wp-proxy-setup.sh 2>&1)

# shellcheck disable=SC2016
expected='wp-proxy: Created vhost for https://www.misterrogers.com at https://misterrogers.tugboat.qa running on backend server http://php.
wp-proxy: Created vhost for http://www.kingfriday.com at http://kingfriday-${TUGBOAT_DEFAULT_SERVICE_TOKEN}.tugboat.qa running on backend server http://nginx.'

if [[ "$output" != "$expected" ]]; then
	echo "✘ The expected output from processing valid.yml does not match." 1>&2
	echo
	echo "Expected output:"
	echo "$expected"
	echo
	echo "Actual output:"
	echo "$output"
	exit 23
fi
echo "✔ Successfully processed valid.yml." 1>&2;

for filepath in test/snapshots/*.vhost; do
	file=$(basename "$filepath")
	test -f dist/conf.d/"$file" || exiterr "The file 'dist/conf.d/$file' does not exist."
	diff=$(diff -u test/snapshots/"$file" dist/conf.d/"$file" || true)
	test -z "$diff" || exiterr "There were differences between 'test/snapshots/$file' and 'dist/conf.d/$file':\n$diff"
done
echo "✔ All files in test/snapshots exist in dist/conf.d and match." 1>&2;
for filepath in dist/conf.d/*.vhost; do
	file=$(basename "$filepath")
	test -f test/snapshots/"$file" || exiterr "The test run created a vhost that does not exist as a snapshot in 'test/snapshots/$file'."
done
echo "✔ All files in dist/conf.d exist in test/snapshots and match." 1>&2;

expected="Error: yaml: mapping values are not allowed in this context
The file './test/ymls/invalid.yml' is not valid yaml."
output=$(WP_PROXY_MAP_FILE=./test/ymls/invalid.yml dist/wp-proxy-setup.sh 2>&1)
test -n "$output" || exiterr "The test/ymls/invalid.yml should result in an error message."
if [[ "$output" != "$expected" ]]; then
	echo "✘ The error message for test/ymls/invalid.yml does not match." 1>&2
	echo
	echo "Expected output:"
	echo "$expected"
	echo
	echo "Actual output:"
	echo "$output"
	exit 23
fi
echo "✔ Asserted that invalid yaml results in an error message." 1>&2;

echo "✔ All tests passed successfully!" 1>&2;
