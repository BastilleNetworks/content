#!/usr/bin/env bash

# exit on errors
set -e

CIRCLE_BRANCH=${CIRCLE_BRANCH:-unknown}
CIRCLE_BUILD_NUM=${CIRCLE_BUILD_NUM:-00000}
CIRCLE_ARTIFACTS=${CIRCLE_ARTIFACTS}
PACK_ARTIFACTS=$CIRCLE_ARTIFACTS/content_packs.zip
EXTRACT_FOLDER=$(mktemp -d)

if [[ -z "$GCS_MARKET_KEY" ]]; then
    echo "$GCS_MARKET_KEY not set aborting!"
    exit 1
fi

echo "Preparing content packs for testing ..."

KF=$(mktemp)
echo "$GCS_MARKET_KEY" > "$KF"
gcloud auth activate-service-account --key-file="$KF" > auth.out 2>&1
echo "Auth loaded successfully."

GCS_MARKET_BUCKET="marketplace-dist"
GCS_BUILD_BUCKET="marketplace-ci-build"
SOURCE_PATH="content/packs"
TARGET_PATH="content/builds/$CIRCLE_BRANCH/$CIRCLE_BUILD_NUM"
echo "Copying master files at: $SOURCE_PATH to target path: $TARGET_PATH ..."
gsutil -m cp -r "gs://$GCS_MARKET_BUCKET/$SOURCE_PATH" "gs://$GCS_BUILD_BUCKET/$TARGET_PATH"
echo "Finished copying successfully."

echo "Updating modified content packs in the bucket ..."

CONTENT_PACKS_TO_INSTALL_FILE="./Tests/content_packs_to_install.txt"
CONTENT_PACKS_TO_INSTALL=$(paste -sd, $CONTENT_PACKS_TO_INSTALL_FILE)

echo "Updating the following content packs: $CONTENT_PACKS_TO_INSTALL ..."
python3 ./Tests/Marketplace/upload_packs.py -a $PACK_ARTIFACTS -e $EXTRACT_FOLDER -b $GCS_BUILD_BUCKET -s $KF -n $CIRCLE_BUILD_NUM -k $PACK_SIGNING_KEY -p CONTENT_PACKS_TO_INSTALL -o -sb $TARGET_PATH -sn false -rt false
echo "Finished updating content packs successfully."

echo "Finished preparing content packs for testing successfully."
