# This runs the tasks in a specific task directory
#
hiveResultTopDir="adHocEtl"
scriptDir=${0%/*}
killHiveScript="killAllJobsFromLog.sh"
# check for and report errors in the config.
# exit after checking all variables
function checkConfig() {
    missingVariable="false"
    if [[ -z ${hiveFileName} ]] ; then
	    echo "hiveFileName not set"
	    missingVariable="true"
    fi
    if [[ -z ${hiveServer} ]] ; then
	    echo "hiveServer not set"
	    missingVariable="true"
    fi
    if [[ -z ${hiveServerUserName} ]] ; then
	    echo "hiveServerUserName not set"
	    missingVariable="true"
    fi
    if [[ -z ${hiveResultFileName} ]] ; then
	    echo "hiveResultFilePath not set"
	    missingVariable="true"
    fi
    if [[ -z ${sqlFileName} ]] ; then
	    echo "sqlFileName not set"
	    missingVariable="true"
    fi
    if [[ -z ${sqlServer} ]] ; then
	    echo "sqlServer not set"
	    missingVariable="true"
    fi
    if [[ -z ${sqlUser} ]] ; then
	    echo "sqlUser not set"
	    missingVariable="true"
    fi
    if [[ -z ${sqlPassword} ]] ; then
	    echo "sqlPassword not set"
	    missingVariable="true"
    fi
    if [[ "${missingVariable}" = "true" ]] ; then
	    echo "One or more configuration values not set"
    fi
}

# The first argument is  directory for the results
function runHiveAndSql() {
    allTaskDir=${1}
    taskDir=${2}
    # make a unique dir for all task 
    hiveDir="${hiveResultTopDir}/${allTaskDir}/${taskDir}"
    let sshStatus=1
    # get a unique name for each file
    fileRoot="$(uuidgen)"
    # add the extensions
    resultFileName="${fileRoot}.result"
    logFileName="${fileRoot}.log"
    tempHiveFileName="${fileRoot}.hive"
    # Check end of file (last 2 lines for "OK" or " Ended Job.* with errors"
    # before cleaningup
    let maxTrys=5
    let taskFailCount=0
    # set these to 1 to get in to the try loop
    let hiveStatus=1
    let sshStatus=1
    while [[ ${sshStatus} -ne 0 && ${hiveStatus} -ne 0  && ${taskFailCount} -lt ${maxTrys} ]]; do 
        # reset to success until proven otherwise
        let hiveStatus=0
        let sshStatus=0
        echo "Starting attempt ${taskFailCount} of ${hiveFileName} taskId: ${fileRoot}"
        # Make the directory as needed
        ssh ${hiveServerUserName}@${hiveServer} "mkdir -p "${hiveDir}
        sshStatus|=$?
        # copy over the hive file
        echo "Copied ${hiveFileName} to ${hiveServerUserName}@${hiveServer}:${hiveDir}/${tempHiveFileName}"
        scp ${hiveFileName} ${hiveServerUserName}@${hiveServer}:${hiveDir}/${tempHiveFileName}
        sshStatus|=$?
        # run the hive file
        ssh ${hiveServerUserName}@${hiveServer} "cd ${hiveDir};cat ${tempHiveFileName} >> ${logFileName}"
        sshStatus|=$?
	    ssh ${hiveServerUserName}@${hiveServer} "cd ${hiveDir};hive -f ${tempHiveFileName} > ${resultFileName} 2>> ${logFileName}"
        sshStatus|=$?
	    # get the results
	    echo "Retrieving ${hiveServerUserName}@${hiveServer}:${hiveDir}/${resultFileName} and log file"
	    scp ${hiveServerUserName}@${hiveServer}:${hiveDir}/${resultFileName} ${hiveResultFileName}
        sshStatus|=$?
	    scp ${hiveServerUserName}@${hiveServer}:${hiveDir}/${logFileName} ${logFileName}
        sshStatus|=$?
	    #If any of the ssh stuff failed we ahve to start over
        if [[ ${sshStatus} -ne 0 ]] ; then
            echo "One more ssh/scp commands failed for task ${fileRoot}"
        # if there were no ssh failures and we have a log file check the log file
        elif [[ -f ${logFileName} ]] ; then 
	        tail $logFileName | grep -q "^OK"
	        hiveStatus=$?
            if [[ ${hiveStatus} -ne 0 ]] ; then
                echo "Attemp ${taskFailCount} failed. Killing jobs in ${logFileName}"
                scp ${scriptDir}/${killHiveScript} ${hiveServerUserName}@${hiveServer}:${hiveDir}/${killHiveScript}
                ssh ${hiveServerUserName}@${hiveServer} "cd ${hiveDir}; chmod +x ${killHiveScript}; cat ${logFileName}|./${killHiveScript}"
                sleep 10
            fi
        else
            echo "${logFileName} missing for no known reason trying again"
        fi
        if [[ ${sshStatus} -ne 0 || ${haveStatus -ne 0 ]] ; then
	        let taskFailCount=taskFailCount+1            
        fi
    done
    if [[ ${taskFailCount} -ne 0 ]] ; then
        echo "${tempHiveFileName} failed ${taskFailCount} times"
    fi
    if [[ ${hiveStatus} -ne 0 ]] ; then
	    echo "ERROR ${tempHiveFileName} never succeeded"
	    return 1
    else
        echo "Finished ${tempHiveFileName} with no apparent errors"
    fi

    echo "Removing files from ${hiveServerUserName}@${hiveServer}:${hiveDir}"
    ssh ${hiveServerUserName}@${hiveServer} "cd ${hiveDir};rm -f ${resultFileName} ${logFileName} ${tempHiveFileName}"
    echo "Task ${fileRoot} loading data from ${sqlPassword} with ${PWD}/${sqlFileName}"
    let mysqlStatus=1
    let mysqlTryCount=0

    #&& [[ "${mysqlTryCount}" -lt "${maxTrys}"]] ]] ;  do
    while [[ ${mysqlStatus} -ne 0  && ${mysqlTryCount} -lt ${maxTrys} ]]; do 
	    mysql --local-infile -h${sqlServer} -u${sqlUser} -p${sqlPassword} < ${sqlFileName}
	    mysqlStatus=$?
	    let mysqlTryCount=mysqlTryCount+1
	    sleep 5
    done
    if [[ ${mysqlStatus} -ne 0 ]] ; then
	    echo "Task ${fileRoot} sql error failed ${mysqlTryCount} times, saving hive results"
        mv ${hiveResultFileName} ${fileRoot}_${hiveResultFileName}
    fi
	rm ${hiveResultFileName}

}
# MAIN
allTasksDirectory=${1}
taskDir=${2}
etlConfigFileName=${3}
. ${etlConfigFileName}
# if we do not get any strings back then execute the task
checkResult="$(checkConfig)"
if [[ -z ${checkResult}  ]] ; then
	echo "Executing etl task in ${taskDir}"
	runHiveAndSql ${allTasksDirectory} ${taskDir}
else
	echo "${checkResult}"
fi
