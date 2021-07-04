#!/bin/sh

if [ "$1" = "" ]; then
    echo "Version 'bump' type is missing. Please try again specifiying 'minor' or 'patch'"
    exit 1
fi

TYPE=$1

##### Constants

BRANCH_DEVELOP=develop
BRANCH_MASTER=master
BRANCH_TESTING=testing
BRANCH_RELEASE_PREFIX=release
BRANCH_HOTFIX_PREFIX=hotfix
BRANCH_FEATURE_PREFIX=feature
BRANCH_RELEASE=release

##### Main

git checkout $BRANCH_MASTER
git pull origin $BRANCH_MASTER
git checkout -b $BRANCH_RELEASE_PREFIX/tmp-version-creation $BRANCH_MASTER
docker-compose exec app php bin/console app:version:bump --$TYPE=1
VERSION=`cat VERSION`
git add .
git commit -am "Version updated"
git checkout -b $BRANCH_RELEASE_PREFIX/$BRANCH_RELEASE-$VERSION
git branch -d $BRANCH_RELEASE_PREFIX/tmp-version-creation 
git push --set-upstream origin $BRANCH_RELEASE_PREFIX/$BRANCH_RELEASE-$VERSION

echo
echo
echo
echo "New Release branch $BRANCH_RELEASE_PREFIX/$BRANCH_RELEASE-$VERSION is ready"
echo "All minor changes and new feature branches should be PR'd and merged here" 
echo
echo "--"
echo

