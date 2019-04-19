#!/bin/bash -x
#  this file contains defaults for currently generated source tarballs

set -e

# TAPSET

export PROJECT_NAME="hg"
export REPO_NAME="icedtea12"
export VERSION="e9b81cef3b83"
export COMPRESSION=xz
export OPENJDK_URL=http://icedtea.classpath.org
export FILE_NAME_ROOT=${PROJECT_NAME}-${REPO_NAME}-${VERSION}
export TO_COMPRESS="*/tapset"
# warning, filename  and filenameroot creation is duplicated here from generate_source_tarball.sh
CLONED_FILENAME=${FILE_NAME_ROOT}.tar.${COMPRESSION}
TAPSET_VERSION=3.2
TAPSET=systemtap_"$TAPSET_VERSION"_tapsets_$CLONED_FILENAME
if [ ! -f ${TAPSET} ] ; then
  if [ ! -f ${CLONED_FILENAME} ] ; then
  echo "Generating ${CLONED_FILENAME}"
    sh ./generate_source_tarball.sh
  else 
    echo "exists exists exists exists exists exists exists "
    echo "reusing reusing reusing reusing reusing reusing "
    echo ${CLONED_FILENAME}
  fi
  mv -v $CLONED_FILENAME  $TAPSET
else 
  echo "exists exists exists exists exists exists exists "
  echo "reusing reusing reusing reusing reusing reusing "
  echo ${TAPSET}
fi

# This will almost always be "jdk" or "jdk-updates" --
# unless you're checking out a special branch such as
# (now obsolete) shenandoah
export PROJECT_NAME="jdk-updates"
# Current tree -- will update to 13 at some point, see
# http://hg.openjdk.java.net/jdk/
# for current options
export REPO_NAME="jdk12u"
# For latest tag, see http://hg.openjdk.java.net/jdk/jdk12/tags
# Or for Shenandoah branch, http://hg.openjdk.java.net/shenandoah/jdk12/tags
export VERSION="jdk-12.0.1-ga"
export COMPRESSION=xz
# unset tapsets overrides
export OPENJDK_URL=""
export TO_COMPRESS=""
# warning, filename  and filenameroot creation is duplicated here from generate_source_tarball.sh
export FILE_NAME_ROOT=${PROJECT_NAME}-${REPO_NAME}-${VERSION}
FILENAME=${FILE_NAME_ROOT}.tar.${COMPRESSION}

if [ ! -f ${FILENAME} ] ; then
echo "Generating ${FILENAME}"
  sh ./generate_source_tarball.sh
else 
  echo "exists exists exists exists exists exists exists "
  echo "reusing reusing reusing reusing reusing reusing "
  echo ${FILENAME}
fi

set +e

major=`echo $REPO_NAME | sed 's/[a-zA-Z]*//g'`
build=`echo $VERSION | sed 's/.*+//g'`
name_helper=`echo $FILENAME | sed s/$major/'%{majorver}'/g `
name_helper=`echo $name_helper | sed s/$build/'%{buildver}'/g `
echo "align specfile acordingly:" 
echo " sed 's/^Source0:.*/Source0: $name_helper/' -i *.spec"
echo " sed 's/^Source8:.*/Source8: $TAPSET/'   -i *.spec"
echo " sed 's/^%global buildver.*/%global buildver        $build/'   -i *.spec"
echo " sed 's/Release:.*/Release: 1/'   -i *.spec"
