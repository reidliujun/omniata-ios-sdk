#!/bin/sh

if [ ! -n "$1" ]; then
    echo "Give the version as a parameter"
    exit -1
fi

VERSION=$1

XCODE_FRAMEWORK=iOmniataAPI.framework.zip
if [ ! -f "$XCODE_FRAMEWORK" ]; then
    echo "XCode Framework missing: $XCODE_FRAMEWORK. Build it first and copy it here and commit to Git"
    exit -1
fi

PAGES_REPOSITY_DIR=../Omniata.github.io
if [ ! -d "$PAGES_REPOSITY_DIR" ]; then
    echo "No Github pages clone in $PAGES_REPOSITY_DIR. Clone that first with 'git clone git@github.com:Omniata/Omniata.github.io.git'"
    exit -1
fi

git tag -a v$VERSION -m "v${VERSION}"
git push -u origin master

# Clean and run doxygen
echo "Creating APIdoc"
rm -rf appledoc
appledoc --output appledoc --create-docset --no-install-docset --project-name OmniataAPI --project-company=Omniata --project-version=1.1 iOmniataAPI/iOmniataAPI.h

# Deploy docs and binary
echo "Copying to Omniata repository"
DIR=`pwd`

PAGES_DIR_RELATIVE=docs/sdks/ios/$VERSION
PAGES_DIR=../Omniata.github.io/$PAGES_DIR_RELATIVE

rm -rf $PAGES_DIR
mkdir $PAGES_DIR
mkdir $PAGES_DIR/apidoc
cp -r appledoc/docset/Contents/Resources/Documents/* $PAGES_DIR/apidoc/
cp $XCODE_FRAMEWORK $PAGES_DIR/

echo "Commiting and pushing"
cd $PAGES_REPOSITY_DIR
git pull
git add $PAGES_DIR_RELATIVE
git commit -m "iOS SDK ${VERSION}" $PAGES_DIR_RELATIVE
git push -u origin master

echo "Ready version $VERSION"

