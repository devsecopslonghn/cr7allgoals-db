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
        BYTEBASE_DEVELOP_STAGE = 'environments/develop'
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
            environment {
                // bytebase-action detects GitHub from these standard variables
                // and publishes its native SQL Review comment.
                GITHUB_ACTIONS = 'true'
                GITHUB_REPOSITORY = 'devsecopslonghn/cr7allgoals-db'
                GITHUB_EVENT_NAME = 'pull_request'
                GITHUB_EVENT_PATH = '.jenkins/github-event.json'
                BYTEBASE_CREDENTIALS = credentials('bytebase-cr7-service-account')
                GITHUB_TOKEN = credentials('github-token')
            }
            steps {
                // The action reads the PR number from GITHUB_EVENT_PATH.
                // Jenkins already exposes it as CHANGE_ID for multibranch PR builds.
                writeFile(
                    file: '.jenkins/github-event.json',
                    text: "{\"number\":${env.CHANGE_ID}}\n"
                )
                script {
                    def reviewStatus = sh(
                        returnStatus: true,
                        script: '''bytebase-action check \\
                          --url "$BYTEBASE_URL" \\
                          --project "$BYTEBASE_PROJECT" \\
                          --service-account "$BYTEBASE_CREDENTIALS_USR" \\
                          --service-account-secret "$BYTEBASE_CREDENTIALS_PSW" \\
                          --targets "$BYTEBASE_TARGETS" \\
                          --file-pattern "$BYTEBASE_FILE_PATTERN" \\
                          --check-release FAIL_ON_ERROR \\
                          --output .jenkins/sql-review.json'''
                    )
                    if (reviewStatus != 0) {
                        currentBuild.result = 'FAILURE'
                    }
                }
                archiveArtifacts(
                    artifacts: '.jenkins/sql-review.json',
                    fingerprint: true,
                    allowEmptyArchive: true
                )
            }
        }

        // The develop rollout is restricted to the real master branch.
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

        stage('Rollout DEVELOP') {
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
                          --target-stage "$BYTEBASE_DEVELOP_STAGE" \\
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
