pipeline {
    agent { label 'docker' }

    options {
        disableConcurrentBuilds()
        timestamps()
        skipDefaultCheckout(true)
    }

    environment {
        BYTEBASE_URL = 'https://bytebase.apps.drgdevlab.com'
        BYTEBASE_PROJECT = 'projects/cr7goal-9xbo'
        BYTEBASE_FILE_PATTERN = 'migrations/*.sql'
        BYTEBASE_TARGETS = 'projects/cr7goal-9xbo/instances/oracle-rvdu/databases/CR7ALLGOALS_APP'
        BYTEBASE_TARGET_STAGE = 'environments/test'
        BYTEBASE_ACTION_IMAGE = 'bytebase/bytebase-action:3.22.1'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('SQL Review') {
            when { changeRequest() }
            steps {
                withCredentials([usernamePassword(credentialsId: 'bytebase-cr7-service-account', usernameVariable: 'BYTEBASE_SERVICE_ACCOUNT', passwordVariable: 'BYTEBASE_SERVICE_ACCOUNT_SECRET')]) {
                    sh '''#!/bin/sh
                        set -eu
                        docker run --rm -v "$WORKSPACE:/workspace" -w /workspace \
                          -e BYTEBASE_SERVICE_ACCOUNT -e BYTEBASE_SERVICE_ACCOUNT_SECRET \
                          "$BYTEBASE_ACTION_IMAGE" bytebase-action check \
                          --url "$BYTEBASE_URL" --project "$BYTEBASE_PROJECT" \
                          --service-account "$BYTEBASE_SERVICE_ACCOUNT" \
                          --service-account-secret "$BYTEBASE_SERVICE_ACCOUNT_SECRET" \
                          --file-pattern "$BYTEBASE_FILE_PATTERN" --targets "$BYTEBASE_TARGETS"
                    '''
                }
            }
        }

        stage('Create Release and Plan') {
            when { branch 'master' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'bytebase-cr7-service-account', usernameVariable: 'BYTEBASE_SERVICE_ACCOUNT', passwordVariable: 'BYTEBASE_SERVICE_ACCOUNT_SECRET')]) {
                    sh '''#!/bin/sh
                        set -eu
                        mkdir -p .jenkins
                        docker run --rm -v "$WORKSPACE:/workspace" -w /workspace \
                          -e BYTEBASE_SERVICE_ACCOUNT -e BYTEBASE_SERVICE_ACCOUNT_SECRET \
                          "$BYTEBASE_ACTION_IMAGE" bytebase-action rollout \
                          --url "$BYTEBASE_URL" --project "$BYTEBASE_PROJECT" \
                          --service-account "$BYTEBASE_SERVICE_ACCOUNT" \
                          --service-account-secret "$BYTEBASE_SERVICE_ACCOUNT_SECRET" \
                          --file-pattern "$BYTEBASE_FILE_PATTERN" --targets "$BYTEBASE_TARGETS" \
                          --output /workspace/.jenkins/bytebase-metadata.json
                    '''
                }
            }
        }

        stage('Rollout DEV') {
            when { branch 'master' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'bytebase-cr7-service-account', usernameVariable: 'BYTEBASE_SERVICE_ACCOUNT', passwordVariable: 'BYTEBASE_SERVICE_ACCOUNT_SECRET')]) {
                    sh '''#!/bin/sh
                        set -eu
                        test -s .jenkins/bytebase-metadata.json
                        plan=$(sed -n 's/.*"plan"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p' .jenkins/bytebase-metadata.json)
                        test -n "$plan"
                        docker run --rm -v "$WORKSPACE:/workspace" -w /workspace \
                          -e BYTEBASE_SERVICE_ACCOUNT -e BYTEBASE_SERVICE_ACCOUNT_SECRET \
                          "$BYTEBASE_ACTION_IMAGE" bytebase-action rollout \
                          --url "$BYTEBASE_URL" --project "$BYTEBASE_PROJECT" \
                          --service-account "$BYTEBASE_SERVICE_ACCOUNT" \
                          --service-account-secret "$BYTEBASE_SERVICE_ACCOUNT_SECRET" \
                          --target-stage "$BYTEBASE_TARGET_STAGE" --plan "$plan"
                    '''
                }
            }
        }
    }

    post {
        always { sh 'rm -rf .jenkins' }
    }
}
