#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

logs() {
    LOG_DIRECTORY=$WORKSPACE/web-app/server/$1
    mkdir -p ${LOG_DIRECTORY}
    CONTAINER_LIST=$(docker ps -a --format '{{.Names}}')
    for CONTAINER in ${CONTAINER_LIST}; do
        docker logs ${CONTAINER} > ${LOG_DIRECTORY}/${CONTAINER}.log 2>&1
    done
}

copy_logs() {

# Call logs function
logs $2 $3

if [ $1 != 0 ]; then
    echo -e "\033[31m $2 test case is FAILED" "\033[0m"
    exit 1
fi
}

cd $WORKSPACE/$BASE_DIR/web-app/server || exit
export PATH=gopath/src/github.com/conglt10/evote/bin:$PATH

LANGUAGE="javascript"

echo -e "\033[1m ${LANGUAGE} Test\033[0m"
echo -e "\033[32m starting web-app/server test (${LANGUAGE})" "\033[0m"
# Start Fabric, and deploy the smart contract
./startFabric.sh ${LANGUAGE}
copy_logs $? web-app/server
# If an application exists for this language, test it

pushd ${LANGUAGE}
    COMMAND=node
    PREFIX=
    SUFFIX=.js
    yarn
    ${COMMAND} ${PREFIX}enrollAdmin${SUFFIX}
    copy_logs $? web-app/server-${LANGUAGE}-enrollAdmin
    ${COMMAND} ${PREFIX}registerUser${SUFFIX}
    copy_logs $? web-app/server-${LANGUAGE}-registerUser
    ${COMMAND} ${PREFIX}query${SUFFIX}
    copy_logs $? web-app/server-${LANGUAGE}-query
    ${COMMAND} ${PREFIX}invoke${SUFFIX}
    copy_logs $? web-app/server-${LANGUAGE}-invoke
popd

docker ps -aq | xargs docker rm -f
docker rmi -f $(docker images -aq dev-*)
docker volume prune -f
docker network prune -f
echo -e "\033[32m finished web-app/server test (${LANGUAGE})" "\033[0m"
