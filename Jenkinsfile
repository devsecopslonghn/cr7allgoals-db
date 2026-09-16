pipeline {
    // The Jenkins agent itself is the Bytebase action image.
    agent {
        docker {
            image 'bytebase/bytebase-action:3.22.1'
            // Clear the image entrypoint so Jenkins can start its shell.
            args '--entrypoint=""'
        }
    }

    options {
        disableConcurrentBuilds()
        timestamps()
        skipDefaultCheckout(true)
    }

    environment {
        BYTEBASE_URL = 'https://bytebase.apps.drgdevlab.com'
        BYTEBASE_PROJECT = 'projects/cr7-allgoal-kvi1'
        BYTEBASE_FILE_PATTERN = 'migrations/V*.sql'
        BYTEBASE_TARGETS = 'instances/oracle-cloud-free-sge0/databases/CR7ALLGOALS_APP'
        BYTEBASE_OUTPUT = '.jenkins/bytebase-metadata.json'
        BYTEBASE_TEST_STAGE = 'environments/test'
        BYTEBASE_PROD_STAGE = 'environments/prod'
        GITHUB_API_URL = 'https://api.github.com'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'mkdir -p .jenkins'
            }
        }

        // Runs for a pull request targeting any branch. It is deliberately not
        // restricted to master/main.
        stage('SQL Review') {
            when {
                changeRequest()
            }
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'bytebase-cr7-service-account',
                            usernameVariable: 'BYTEBASE_SERVICE_ACCOUNT',
                            passwordVariable: 'BYTEBASE_SERVICE_ACCOUNT_SECRET'
                        ),
                        string(
                            credentialsId: 'github-token',
                            variable: 'GITHUB_TOKEN'
                        )
                    ]) {
                        def reviewStatus = sh(
                            returnStatus: true,
                            script: '''#!/bin/sh
                                set +e

                                repository="${GITHUB_REPOSITORY:-}"
                                if [ -z "$repository" ]; then
                                    source_url="${CHANGE_URL:-${GIT_URL:-}}"
                                    case "$source_url" in
                                        git@github.com:*)
                                            repository="${source_url#git@github.com:}"
                                            ;;
                                        https://*|http://*)
                                            repository="$(printf '%s' "$source_url" | sed -E 's#^https?://[^/]+/##; s#/pull/[0-9]+/?$##')"
                                            ;;
                                    esac
                                    repository="${repository%.git}"
                                    repository="${repository%/}"
                                fi

                                test -n "$repository"
                                printf '{"number":%s}\n' "$CHANGE_ID" > .jenkins/github-event.json

                                # Make bytebase-action use its native GitHub output
                                # while the job is actually running in Jenkins.
                                export GITHUB_ACTIONS=true
                                export GITHUB_REPOSITORY="$repository"
                                export GITHUB_EVENT_NAME=pull_request
                                export GITHUB_EVENT_PATH=.jenkins/github-event.json
                                export GITHUB_API_URL="${GITHUB_API_URL:-https://api.github.com}"

                                bytebase-action check \\
                                  --url "$BYTEBASE_URL" \\
                                  --project "$BYTEBASE_PROJECT" \\
                                  --service-account "$BYTEBASE_SERVICE_ACCOUNT" \\
                                  --service-account-secret "$BYTEBASE_SERVICE_ACCOUNT_SECRET" \\
                                  --targets "$BYTEBASE_TARGETS" \\
                                  --file-pattern "$BYTEBASE_FILE_PATTERN" \\
                                  --check-release FAIL_ON_ERROR \\
                                  --output .jenkins/sql-review.json \\
                                  > .jenkins/sql-review.log 2>&1
                                status=$?
                                cat .jenkins/sql-review.log
                                exit "$status"
                            '''
                        )

                        // Keep the pipeline moving long enough to publish the
                        // result to the pull request, then fail the build.
                        env.SQL_REVIEW_STATUS = reviewStatus.toString()
                        if (reviewStatus != 0) {
                            currentBuild.result = 'FAILURE'
                        }
                    }
                }
            }
        }

        // All rollout stages are restricted to the real master branch.
        // A PR build has a branch name such as PR-123, so it cannot deploy.
        stage('Create Rollout Plan') {
            when {
                branch 'master'
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'bytebase-cr7-service-account',
                        usernameVariable: 'BYTEBASE_SERVICE_ACCOUNT',
                        passwordVariable: 'BYTEBASE_SERVICE_ACCOUNT_SECRET'
                    )
                ]) {
                    sh '''#!/bin/sh
                        set -eu
                        bytebase-action rollout \\
                          --url "$BYTEBASE_URL" \\
                          --project "$BYTEBASE_PROJECT" \\
                          --service-account "$BYTEBASE_SERVICE_ACCOUNT" \\
                          --service-account-secret "$BYTEBASE_SERVICE_ACCOUNT_SECRET" \\
                          --targets "$BYTEBASE_TARGETS" \\
                          --file-pattern "$BYTEBASE_FILE_PATTERN" \\
                          --output "$BYTEBASE_OUTPUT"

                        plan=$(jq -r '.plan // empty' "$BYTEBASE_OUTPUT")
                        test -n "$plan"
                        printf '%s' "$plan" > .jenkins/bytebase-plan
                    '''
                }
            }
        }

        stage('Rollout TEST') {
            when {
                branch 'master'
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'bytebase-cr7-service-account',
                        usernameVariable: 'BYTEBASE_SERVICE_ACCOUNT',
                        passwordVariable: 'BYTEBASE_SERVICE_ACCOUNT_SECRET'
                    )
                ]) {
                    sh '''#!/bin/sh
                        set -eu
                        bytebase-action rollout \\
                          --url "$BYTEBASE_URL" \\
                          --project "$BYTEBASE_PROJECT" \\
                          --service-account "$BYTEBASE_SERVICE_ACCOUNT" \\
                          --service-account-secret "$BYTEBASE_SERVICE_ACCOUNT_SECRET" \\
                          --target-stage "$BYTEBASE_TEST_STAGE" \\
                          --plan "$(cat .jenkins/bytebase-plan)"
                    '''
                }
            }
        }

        stage('Rollout PROD') {
            when {
                branch 'master'
            }
            steps {
                input message: 'Deploy this Bytebase plan to production?', ok: 'Deploy'
                withCredentials([
                    usernamePassword(
                        credentialsId: 'bytebase-cr7-service-account',
                        usernameVariable: 'BYTEBASE_SERVICE_ACCOUNT',
                        passwordVariable: 'BYTEBASE_SERVICE_ACCOUNT_SECRET'
                    )
                ]) {
                    sh '''#!/bin/sh
                        set -eu
                        bytebase-action rollout \\
                          --url "$BYTEBASE_URL" \\
                          --project "$BYTEBASE_PROJECT" \\
                          --service-account "$BYTEBASE_SERVICE_ACCOUNT" \\
                          --service-account-secret "$BYTEBASE_SERVICE_ACCOUNT_SECRET" \\
                          --target-stage "$BYTEBASE_PROD_STAGE" \\
                          --plan "$(cat .jenkins/bytebase-plan)"
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'rm -rf .jenkins'
        }
    }
}
