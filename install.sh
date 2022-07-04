#!/usr/bin/env bash

set -eEuxo pipefail
# e: all non-zero return codes cause a script to terminate, returning 1
# E: fix for traps when using -e
# x: print each command as it's executed
# u: calls to unset variables cause the script to terminate, returning, 1
# pipefail: exit 1 in any part of a pipe chain cause an overall 1 for the pipe

function main {

	# Running as non-root
	if [[ $(id -u) -ne 0 ]]; then
		exit_error "This script should be run as root."
	fi

	# First argument isn't set
	if [ -n "$1" ]; then
		exit_error "The first argument should be the path to the git repository."
	fi

	# Second argument isn't set
	if [ -n "$2" ]; then
		exit_error "The second argument should be the git branch name."
	fi

	# Third argument isn't set
	if [ -n "$3" ]; then
		exit_error "The third argument should be the name of the daemon to install."
	fi

	path_to_git_repository="$1"
	git_branch="$2"
	daemon_name="$3"
	git_daemons_dir="/opt/git-daemons"
	this_git_daemon_path="$git_daemons_dir/$daemon_name.sh"
	path_of_this_directory="$(dirname "$(readlink -f "$0")")"

	cd "$path_to_git_repository" || {
		exit_error "cd $path_to_git_repository failed."
	}

	# Required for multiple local users to use a single git repo
	git config core.sharedrepository true

	# Create a directory to hold all git daemons, if it doesn't exist
	mkdir -p "$git_daemons_dir"
	chmod 700 "$git_daemons_dir"

	# Install the current git daemon
	cp -f "$path_of_this_directory/daemon.sh" "$this_git_daemon_path"
	chmod u+x "$this_git_daemon_path"

	cp -f "$path_of_this_directory/daemon.sh" "$this_git_daemon_path"
	systemctl enable --now "$daemon_name.service"
}

function exit_error {
	echo "$1" | tee /dev/stderr
	exit 1
}

main "$@"
