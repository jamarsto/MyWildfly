#!/bin/bash
function start_the_services() {
	unset restart_requested

	/opt/jboss/wildfly/bin/standalone.sh -b 0.0.0.0 &> /dev/null &
	wildfly_pid=$!

	until `/opt/jboss/wildfly/bin/jboss-cli.sh -c "ls /deployment" &> /dev/null`; do
		sleep 1
	done

	httpd -k start &> /dev/null
}

function stop_the_services() {
	httpd -k stop &> /dev/null
	kill -n 15 $wildfly_pid

	count=0
	while kill -n 0 $wildfly_pid &> /dev/null; do
		count=`expr $count + 1`
		if [ $count -ge 180 ]; then
			break;
		fi
		sleep 1; 
	done

	if kill -n 0 $wildfly_pid &> /dev/null; then
		kill -n 9 $wildfly_pid
	fi

	unset wildfly_pid
	unset restart_requested
}

function terminate_the_services() {
 	terminate=1
}
trap 'terminate_the_services' SIGINT SIGQUIT SIGILL SIGABRT SIGFPE SIGTERM SIGTSTP

function cause_a_service_restart() {
	restart_requested=1
}
trap 'cause_a_service_restart' SIGHUP

function cache_file_changes_that_cause_a_restart() {
	config_count=$(rsync -a --stats /home/site/wwwroot/configuration/ /opt/jboss/wildfly/customisation/configuration 2>&1 | grep "transferred:" | grep -E -o "([0-9]+)")
	if [ -z "$config_count" ]; then config_count=0; fi

	module_count=$(rsync -a --stats /home/site/wwwroot/modules/ /opt/jboss/wildfly/customisation/modules 2>&1 | grep "transferred:" | grep -E -o "([0-9]+)")
	if [ -z "$module_count" ]; then module_count=0; fi

	file_changes_that_cause_a_restart=`expr $config_count + $module_count`
	config_count=0
	module_count=0
}

function apply_all_the_file_changes() {
	rsync -a /opt/jboss/wildfly/customisation/configuration/ /opt/jboss/wildfly/standalone/configuration &> /dev/null

	rsync -a /opt/jboss/wildfly/customisation/modules/ /opt/jboss/wildfly/modules/system/layers/base &> /dev/null

	rsync -a --include='*/' --include='*.war' --include='*.ear' --exclude='*' /home/site/wwwroot/deployments /opt/jboss/wildfly/standalone/deployments &> /dev/null
}

/usr/sbin/sshd 

# Loop until we receive an interrupt or terminate signal
while [ -z "$terminate" ]; do 
	cache_file_changes_that_cause_a_restart

	# If there are file changes that cause a restart or a restart
	# has been requested, and Wildfly is running, stop the services
	if ([ $file_changes_that_cause_a_restart -gt 0 ] || [ ! -z "$restart_requested" ]) && [ ! -z "$wildfly_pid" ]; then
		stop_the_services
	fi

	apply_all_the_file_changes

	# If Wildfly is not running, start the services
	if [ -z "$wildfly_pid" ]; then
		start_the_services
	fi

	sleep 10
done

stop_the_services
