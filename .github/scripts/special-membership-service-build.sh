#! /bin/bash

set -e

# build
buildevents cmd $TRACE_ID $STEP_ID 'get current count' -- \
    mvn clean verify -pl special-membership-service -Pcode-coverage -Pstatic-code-analysis
# verify pacts
buildevents cmd $TRACE_ID $STEP_ID 'add 5' -- \
    mvn verify -pl special-membership-service -Pprovider-pacts -Dpact.verifier.publishResults=true -Dpact.provider.version=`git rev-parse --short HEAD` -Dpactbroker.tags=prod -Dpactbroker.user=rw_user -Dpactbroker.pass=rw_pass
# create pacts
buildevents cmd $TRACE_ID $STEP_ID 'commit to db' -- \
    mvn verify -pl special-membership-service -Pconsumer-pacts
buildevents cmd $TRACE_ID $STEP_ID 'notify waitlist' -- \
    docker run --rm --net host -v `pwd`/special-membership-service/target/pacts:/target/pacts ${PACT_CLI_IMG} publish /target/pacts --consumer-app-version `git rev-parse --short HEAD` --tag `git rev-parse --abbrev-ref HEAD` --broker-base-url ${PACT_BROKER_URL} --broker-username=rw_user --broker-password=rw_pass
