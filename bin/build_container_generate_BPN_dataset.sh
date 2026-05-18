#!/usr/bin/bash
# To be ran from the experiments directory.
# Not from the source repository.

set -e
set -o pipefail

function git_rev()
{
    last_commit_date=$(git log -1 --format=%ci | awk '{print $1"_"$2;}' | sed "s/:/-/g")
    branch=$(git rev-parse --abbrev-ref HEAD)
    echo "${branch}_${last_commit_date}"
}

function git_archive()
{
    project=$(basename $(pwd))
    name=${project}_$(git_rev)
    branch=$(git rev-parse --abbrev-ref HEAD)
    git config tar.tar.xz.command "xz -c"
    git archive --prefix=$name/ --format tar.xz ${branch} > $name.tar.xz
    echo $name.tar.xz
}

EXPE="$(pwd)"

# Go to the repository
cd $(dirname $0)/..

if [[ ! -f "generate_BPN_dataset.def" ]] ; then
    echo "ERROR: the given path does not point to a ValidationGraphGeneration repository." >&2
    exit 2
fi

# If the repository is not clean
# (i.e. there are uncommitted changes)
MSG=""
if ! git diff-index --quiet HEAD -- ; then
    MSG="WARNING: this repository has uncommited changes, I will archive the last committed version. Please commit before running this script, or else you will not build what you expects."
fi

ARCHIVE=$(git_archive .)

if command -v module ; then
    module load apptainer
fi
apptainer cache clean -f
REV=$(git_rev)
apptainer build -F generate_BPN_dataset__$REV.sif generate_BPN_dataset.def

mv -n $ARCHIVE $EXPE/
mv -n generate_BPN_dataset__$REV.sif $EXPE/
rm -f $EXPE/generate_BPN_dataset.sif
ln -s $EXPE/generate_BPN_dataset__$REV.sif $EXPE/generate_BPN_dataset.sif

echo "Archived code version in: $ARCHIVE" >&2
echo "$MSG" >&2

