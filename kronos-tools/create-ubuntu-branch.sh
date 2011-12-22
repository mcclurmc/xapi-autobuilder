#!/bin/bash

set -e
set -x

# Ubuntu, like Debian, allows only one distribution per changelog entry. So
# we'll loop through a list of distributions we want to support, and build and
# push those.

DISTROS=oneiric precise

# If ubuntu-${distro} branch exists, check it out and use it, as it's being
# managed manually. Otherwise, create the ubuntu branch from the debian
# branch.

git checkout master
git fetch origin debian:debian

for distro in ${DISTROS}; do

	ubuntu=ubuntu-${distro}

	# Does ubuntu branch exist? Check it out and exit.
	if [ `git branch -a | grep "remotes/origin/${ubuntu}$"` ]; then
		git checkout ${ubuntu}
		exit 0
	fi

	# Ubuntu branch doesn't exist on remote. Delete any local ubuntu branch, create
	# it from debian branch, and bump changelog.
	git branch -D ${ubuntu} || true
	git branch ${ubuntu} debian
	git checkout ${ubuntu}

	version=$(dpkg-parsechangelog -c1 -ldebian/changelog | grep Version | cut -f2 -d' ')
	dch -v ${version}ubuntu1 "Ubuntu ${distro} stamp" --distribution "${distro}" --force-distribution
	git commit -a -m "Ubuntu ${distro} stamp"
done
