export HASH=QmbBTpn7nZeAm4gZfK6DK5JGxZe9yBjqfGHvMYAFt9AXqa
tmpfile=$(mktemp /tmp/download_ipfs.$HASH.XXXXXX)
curl https://ipfs.io/ipfs/$HASH > $tmpfile
mkdir -p ipfs/$HASH
grep /ipfs/$HASH/ $tmpfile | \
  cut -d'"' -f2 | \
  xargs -I{} curl -L -o .{} https://ipfs.io/{}
