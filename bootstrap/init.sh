#! /usr/bin/env bash

export BOOTSTRAP_DIR=$(dirname $(realpath -s $BASH_SOURCE))
export PATH=$BOOTSTRAP_DIR/bin:$PATH

# source all utils
for f in $BOOTSTRAP_DIR/utils/*; do source $f; done

# source all pre-bootstrap scripts
for f in $BOOTSTRAP_DIR/pre/*; do source $f; done

tasks_dir=$BOOTSTRAP_DIR/tasks

all_task_file_names=($(ls $tasks_dir))
tasks_args=()
declare -A running_tasks

function arg_task_to_long_file_name() {
	for task_file_name in "${all_task_file_names[@]}"; do
		short_name=$(task_file_long_to_short_name $task_file_name)
		if [[ $short_name == $1 ]]; then
			echo $task_file_name
			return
		fi
	done
}

function task_file_long_to_short_name() {
	echo $1 | sed -e "s/.*___//"
}

echo "==============================================>"

while [[ "$#" -gt 0 ]]; do
	case $1 in

	-t | --tasks)
		if [[ -z $2 ]] || [[ $2 == -* ]]; then
			echo "no list of tasks have been passed"
			exit 1
		else
			shift

			while [[ ! -z "$1" ]] && [[ $1 != -* ]]; do
				task_file_name=$(arg_task_to_long_file_name $1)
				if [[ ! -z $task_file_name ]]; then
					tasks_args+=($1)
					running_tasks[$1]=$task_file_name
					shift
				else
					error "wrong task name: $1"
					exit 1
				fi
			done

			continue
		fi
		;;

	*)
		echo "Unknown parameter passed: $1"
		exit 1
		;;

	esac
done

# if no individual tasks are passed, then execute all tasks by default
if [[ ${#running_tasks[@]} -eq 0 ]]; then
	for task_file_name in "${all_task_file_names[@]}"; do
		running_tasks[$(task_file_long_to_short_name $task_file_name)]=$task_file_name
	done
fi

# order tasks alphabetically (even when individual tasks are passed) so that dependencies among tasks are not messed up
ordered_task_names=$(
	for key in ${!running_tasks[@]}; do
		echo "${running_tasks[$key]}:::$key"
	done | sort | awk -F::: '{print $2}'
)

log "about to run this ${#ordered_task_names[@]} tasks:"
for task_name in $ordered_task_names; do
	log "   $task_name"
done

echo
log "Do you want to proceed? (yes/y/no/n) (default to no) "
read -p "" proceed
case $proceed in
yes | y)
	echo
	for task_name in $ordered_task_names; do
		log "starting task: $task_name"
		source "$tasks_dir/${running_tasks[$task_name]}"
		log "ending task: $task_name\n"
	done
	;;
*)
	echo exiting...
	exit
	;;
esac

# source all post-bootstrap scripts
for f in $BOOTSTRAP_DIR/post/*; do source $f; done

unset BOOTSTRAP_DIR
