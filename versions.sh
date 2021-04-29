#!/usr/bin/env bash
set -Eeuo pipefail

defaultAlpineVersion='3.13'
declare -A alpineVersion=(
	#[17.09]='3.6'
)

# bashbrew arch to docker-release-arch
declare -A dockerArches=(
	['amd64']='x86_64'
	['arm32v6']='armel'
	['arm32v7']='armhf'
	['arm64v8']='aarch64'
	['ppc64le']='ppc64le'
	['s390x']='s390x'
#	['windows-amd64']='windows-amd64'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
	json='{}'
else
	json="$(< versions.json)"
fi
versions=( "${versions[@]%/}" )

# "tac|tac" for http://stackoverflow.com/a/28879552/433558
dindLatest="$(curl -fsSL 'https://github.com/docker/docker/commits/master/hack/dind.atom' | tac|tac | awk -F '[[:space:]]*[<>/]+' '$2 == "id" && $3 ~ /Commit/ { print $4; exit }')"

dockerVersions="$(
	git ls-remote --tags https://github.com/docker/docker.git \
		| cut -d$'\t' -f2 \
		| grep '^refs/tags/v[0-9].*$' \
		| sed 's!^refs/tags/v!!; s!\^{}$!!' \
		| sort -u \
		| gawk '
			{ data[lines++] = $0 }

			# "beta" sorts lower than "tp" even though "beta" is a more preferred release, so we need to explicitly adjust the sorting order for RCs
			# also, "18.09.0-ce-beta1" vs "18.09.0-beta3"
			function docker_version_compare(i1, v1, i2, v2, l, r) {
				l = v1; gsub(/-ce/, "", l); gsub(/-tp/, "-alpha", l)
				r = v2; gsub(/-ce/, "", r); gsub(/-tp/, "-alpha", r)
				patsplit(l, ltemp, /[^.-]+/)
				patsplit(r, rtemp, /[^.-]+/)
				for (i = 0; i < length(ltemp) && i < length(rtemp); ++i) {
					if (ltemp[i] < rtemp[i]) {
						return -1
					}
					if (ltemp[i] > rtemp[i]) {
						return 1
					}
				}
				return 0
			}

			END {
				asort(data, result, "docker_version_compare")
				for (i in result) {
					print result[i]
				}
			}
		'
)"

for version in "${versions[@]}"; do
	rcVersion="${version%-rc}"
	channel='stable'
	alpine="${alpineVersion[$version]:-$defaultAlpineVersion}"

	versionOptions="$(grep "^$rcVersion[.]" <<<"$dockerVersions")"

	rcGrepV='-v'
	if [ "$rcVersion" != "$version" ]; then
		rcGrepV=
		channel='test'
	fi

	fullVersion="$(grep $rcGrepV -E -- '-(rc|tp|beta)' <<<"$versionOptions" | tail -1)"
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi

	echo "$version: $fullVersion"

	export fullVersion alpine dindLatest
	doc="$(
		jq -nc '{
			version: env.fullVersion,
			arches: {},
			alpine: env.alpine,
			dindCommit: env.dindLatest,
		}'
	)"

	for bashbrewArch in "${!dockerArches[@]}"; do
		arch="${dockerArches[$bashbrewArch]}"
		# check whether the given architecture is supported for this release
		url="https://download.docker.com/linux/static/$channel/$arch/docker-$fullVersion.tgz"
		if wget --quiet --spider "$url" &> /dev/null; then
			export bashbrewArch url
			doc="$(
				jq <<<"$doc" -c '.arches[env.bashbrewArch] = {
					dockerUrl: env.url,
				}'
			)"
		else
			continue
		fi

		rootlessExtrasUrl="https://download.docker.com/linux/static/$channel/$arch/docker-rootless-extras-$fullVersion.tgz"
		# https://github.com/docker/docker-ce/blob/8fb3bb7b2210789a4471c017561c1b0de0b4f145/components/engine/hack/make/binary-daemon#L24
		# "vpnkit is amd64-only" ... for now??
		if [ "$bashbrewArch" = 'amd64' ] && wget --quiet --spider "$rootlessExtrasUrl" &> /dev/null; then
			export rootlessExtrasUrl
			doc="$(
				jq <<<"$doc" -c \
					'.arches[env.bashbrewArch].rootlessExtrasUrl = env.rootlessExtrasUrl'
			)"
		fi
	done

	# order here controls the order of the library/ file
	for variant in \
		'' \
		dind \
		dind-rootless \
		git \
	; do
		base="${variant%%/*}" # "buster", "windows", etc.
		[ -d "$version/$base" ] || continue
		export variant
		doc="$(jq <<<"$doc" -c '.variants += [ env.variant ]')"
	done

	export version
	json="$(jq <<<"$json" -c --argjson doc "$doc" '.[env.version] = $doc')"
done

jq <<<"$json" -S . > versions.json
