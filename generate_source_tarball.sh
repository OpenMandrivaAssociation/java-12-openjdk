#!/bin/bash
# Generates the 'source tarball' for JDK projects.
#
# Example:
# When used from local repo set REPO_ROOT pointing to file:// with your repo
# if your local repo follows upstream forests conventions, you may be enough by setting OPENJDK_URL
# if you wont to use local copy of patch PR2126 set path to it to PR2126 variable
#
# In any case you have to set PROJECT_NAME REPO_NAME and VERSION. eg:
# PROJECT_NAME=jdk
# REPO_NAME=jdk
# VERSION=tip
# or to eg prepare systemtap:
# icedtea7's jstack and other tapsets
# VERSION=6327cf1cea9e
# REPO_NAME=icedtea7-2.6
# PROJECT_NAME=release
# OPENJDK_URL=http://icedtea.classpath.org/hg/
# TO_COMPRESS="*/tapset"
# 
# They are used to create correct name and are used in construction of sources url (unless REPO_ROOT is set)

# This script creates a single source tarball out of the repository
# based on the given tag and removes code not allowed in fedora/rhel. For
# consistency, the source tarball will always contain 'openjdk' as the top
# level folder, name is created, based on parameter
#

if [ ! "x$PR2126" = "x" ] ; then
  if [ ! -f "$PR2126" ] ; then
    echo "You have specified PR2126 as $PR2126 but it does not exists. exiting"
    exit 1
  fi
fi

set -e

OPENJDK_URL_DEFAULT=http://hg.openjdk.java.net
COMPRESSION_DEFAULT=xz

if [ "x$1" = "xhelp" ] ; then
    echo -e "Behaviour may be specified by setting the following variables:\n"
    echo "VERSION - the version of the specified OpenJDK project"
    echo "PROJECT_NAME -- the name of the OpenJDK project being archived (optional; only needed by defaults)"
    echo "REPO_NAME - the name of the OpenJDK repository (optional; only needed by defaults)"
    echo "OPENJDK_URL - the URL to retrieve code from (optional; defaults to ${OPENJDK_URL_DEFAULT})"
    echo "COMPRESSION - the compression type to use (optional; defaults to ${COMPRESSION_DEFAULT})"
    echo "FILE_NAME_ROOT - name of the archive, minus extensions (optional; defaults to PROJECT_NAME-REPO_NAME-VERSION)"
    echo "REPO_ROOT - the location of the Mercurial repository to archive (optional; defaults to OPENJDK_URL/PROJECT_NAME/REPO_NAME)"
    echo "TO_COMPRESS - what part of clone to pack (default is openjdk)"
    echo "PR2126 - the path to the PR2126 patch to apply (optional; downloaded if unavailable)"
    exit 1;
fi


if [ "x$VERSION" = "x" ] ; then
    echo "No VERSION specified"
    exit -2
fi
echo "Version: ${VERSION}"
    
# REPO_NAME is only needed when we default on REPO_ROOT and FILE_NAME_ROOT
if [ "x$FILE_NAME_ROOT" = "x" -o "x$REPO_ROOT" = "x" ] ; then
  if [ "x$PROJECT_NAME" = "x" ] ; then
    echo "No PROJECT_NAME specified"
    exit -1
  fi
  echo "Project name: ${PROJECT_NAME}"
  if [ "x$REPO_NAME" = "x" ] ; then
    echo "No REPO_NAME specified"
    exit -3
  fi
  echo "Repository name: ${REPO_NAME}"
fi

if [ "x$OPENJDK_URL" = "x" ] ; then
    OPENJDK_URL=${OPENJDK_URL_DEFAULT}
    echo "No OpenJDK URL specified; defaulting to ${OPENJDK_URL}"
else
    echo "OpenJDK URL: ${OPENJDK_URL}"
fi

if [ "x$COMPRESSION" = "x" ] ; then
    # rhel 5 needs tar.gz
    COMPRESSION=${COMPRESSION_DEFAULT}
fi
echo "Creating a tar.${COMPRESSION} archive"

if [ "x$FILE_NAME_ROOT" = "x" ] ; then
    FILE_NAME_ROOT=${PROJECT_NAME}-${REPO_NAME}-${VERSION}
    echo "No file name root specified; default to ${FILE_NAME_ROOT}"
fi
if [ "x$REPO_ROOT" = "x" ] ; then
    REPO_ROOT="${OPENJDK_URL}/${PROJECT_NAME}/${REPO_NAME}"
    echo "No repository root specified; default to ${REPO_ROOT}"
fi;

if [ "x$TO_COMPRESS" = "x" ] ; then
    TO_COMPRESS="openjdk"
    echo "No to be compressed targets specified, ; default to ${TO_COMPRESS}"
fi;

if [ -d ${FILE_NAME_ROOT} ] ; then
  echo "exists exists exists exists exists exists exists "
  echo "reusing reusing reusing reusing reusing reusing "
  echo ${FILE_NAME_ROOT}
else
  mkdir "${FILE_NAME_ROOT}"
  pushd "${FILE_NAME_ROOT}"
    echo "Cloning ${VERSION} root repository from ${REPO_ROOT}"
    hg clone ${REPO_ROOT} openjdk -r ${VERSION}
  popd
fi

if [ "$PROJECT_NAME" != "hg" ]; then
	echo "Removing in-tree libraries"
	OURDIR=$(realpath $(dirname $0))
	cd ${FILE_NAME_ROOT}
	$OURDIR/remove-intree-libraries.sh
	cd ..
fi

pushd "${FILE_NAME_ROOT}"
    if [ -d openjdk/src ]; then 
        pushd openjdk
            echo "Removing EC source code we don't build"
            CRYPTO_PATH=src/jdk.crypto.ec/share/native/libsunec/impl
            rm -vrf $CRYPTO_PATH
            echo "Syncing EC list with NSS"
            if [ "x$PR2126" = "x" ] ; then
                # From IcedTea: http://icedtea.classpath.org/hg/icedtea?cmd=changeset;node=8d2c9a898f50
                # http://icedtea.classpath.org/bugzilla/show_bug.cgi?id=2126
		PR2126="$(ls ../../pr2126*.patch)"
            fi;
            echo "Applying ${PR2126}"
            patch -Np1 < $PR2126
            find . -name '*.orig' -exec rm -vf '{}' ';'
        popd
    fi

    echo "Compressing remaining forest"
    if [ "X$COMPRESSION" = "Xxz" ] ; then
        SWITCH=cJf
    else
        SWITCH=czf
    fi
    tar --exclude-vcs -$SWITCH ${FILE_NAME_ROOT}.tar.${COMPRESSION} $TO_COMPRESS
    mv ${FILE_NAME_ROOT}.tar.${COMPRESSION}  ..
popd
echo "Done. You may want to remove the uncompressed version - $FILE_NAME_ROOT."


