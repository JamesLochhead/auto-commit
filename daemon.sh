#!/usr/bin/env bash

set -eEuxo pipefail
# e: all non-zero return codes cause a script to terminate, returning 1
# E: fix for traps when using -e
# x: print each command as it's executed
# u: calls to unset variables cause the script to terminate, returning, 1
# pipefail: exit 1 in any part of a pipe chain cause an overall 1 for the pipe

path_to_git_repository="$1"
git_branch="$2"
commit_message="$3"

function main {
	inotifywait -r -m "$path_to_git_repository" -e create -e move -e delete -e modify --exclude ".*\.git.*" |
		while read -r; do
			repo_changed
		done
}

function repo_changed {
	cd "$path_to_git_repository" || {
		echo "cd $path_to_git_repository" | tee /dev/stderr
		exit 1
	}

	# Create git_branch if it doesn't exist and sets the remote branch
	if git rev-parse --verify "$git_branch" > /dev/null 2>&1; then
		git checkout -b "$git_branch"
		git branch --set-upstream-to origin/"$git_branch"
	fi

	# Commit changes and push
	git checkout "$git_branch" 2>/dev/null ||
		git checkout -b "$git_branch" &&
		git add -A &&
		git commit -m "$commit_message" &&
		git push origin "$git_branch"
}

main "$@"
