#!/usr/bin/env bash

currentVersion=$(git describe --tags --abbrev=0)
latestVersion=v$(git -c "versionsort.suffix=-" \
        ls-remote --refs --sort="version:refname" --tags https://github.com/adnanh/webhook.git \
    | tail --lines=1 \
    | cut --delimiter="/" --fields=3)

echo "Current Version: $currentVersion"
echo "Latest Version: $latestVersion"

if [[ "$currentVersion" == "$latestVersion" ]]; then
    echo "Everything up-to-date"
    exit 3
fi

if [[ ! "$latestVersion" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Failed to parse '$latestVersion' as a SemVer"
    exit 1
fi

if [[ "$CI" = "true" ]]; then
    echo "TAG_NAME=$latestVersion" > env.properties
else
    git push origin "$latestVersion"
fi
