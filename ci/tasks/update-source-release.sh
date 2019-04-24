#!/bin/bash -eux
LATEST_RELEASE_URL="https://bosh.io/d/github.com/cloudfoundry/${BOSH_IO_RELEASE}"
UPDATE_RELEASE_OPS_FILE=update-release-ops.yml

wget ${LATEST_RELEASE_URL} -O release.tgz
tar -xzf release.tgz "./release.MF"

URL="https://bosh.io/d/github.com/cloudfoundry/${BOSH_IO_RELEASE}?v=${VERSION}"
RELEASE_NAME="$( bosh int release.MF --path /name )"
VERSION="$( bosh int release.MF --path /version )"
SHA1="$(sha1sum release/*.tgz | cut -d' ' -f1)"

cat << EOF > $UPDATE_RELEASE_OPS_FILE
---
- type: replace
  path: /releases/name=${RELEASE_NAME}
  value:
    sha1: ${SHA1}
    url: ${URL}
    version: "${VERSION}"
    name: ${RELEASE_NAME}
EOF

git clone bosh-deployment bosh-deployment-output

TMP=$(mktemp)
bosh int bosh-deployment/${FILE_TO_UPDATE} -o update-release-ops.yml > $TMP
mv $TMP bosh-deployment-output/${FILE_TO_UPDATE}

pushd $PWD/bosh-deployment-output
  git add -A
  git config --global user.email "ci@localhost"
  git config --global user.name "CI Bot"
  git commit -m "Bumping $RELEASE_NAME to version $VERSION"
popd
