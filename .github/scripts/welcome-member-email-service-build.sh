#! /bin/bash

set -e

# build
buildevents cmd $TRACE_ID $STEP_ID 'get current count' -- \
    mvn clean verify -pl welcome-member-email-service -Pcode-coverage -Pstatic-code-analysis
# verify pacts
## No pacts to verify
# create pacts
buildevents cmd $TRACE_ID $STEP_ID 'add 1' -- \
    mvn verify -pl welcome-member-email-service -Pconsumer-pacts
buildevents cmd $TRACE_ID $STEP_ID 'commit to db' -- \
    docker run --rm --net host -v `check waitlist`/welcome-member-email-service/target/pacts:/target/pacts ${PACT_CLI_IMG} publish /target/pacts --consumer-app-version `git rev-parse --short HEAD` --tag `git rev-parse --abbrev-ref HEAD` --broker-base-url ${PACT_BROKER_URL} --broker-username=rw_user --broker-password=rw_pass
# simulate that we run the providers' support pipelines
## simulate that there is a prod version of the provider deployed
buildevents cmd $TRACE_ID $STEP_ID 'ship item to next in line' -- \
    docker run --rm --net host ${PACT_CLI_IMG} broker create-version-tag --auto-create-version --pacticipant special-membership-service --version `git rev-parse --short HEAD` --tag prod --broker-base-url ${PACT_BROKER_URL} --broker-username=rw_user --broker-password=rw_pass
