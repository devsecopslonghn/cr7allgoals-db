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
                        )
                    ]) {
                        def reviewStatus = sh(
                            returnStatus: true,
                            script: '''#!/bin/sh
                                set +e
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
            post {
                always {
                    script {
                        // Bind a GitHub PAT stored as a Jenkins Secret text credential.
                        if (env.CHANGE_ID) {
                            def reviewStatus = env.SQL_REVIEW_STATUS == '0' ? '✅ Passed' : '❌ Failed'
                            def reviewOutput = fileExists('.jenkins/sql-review.log')
                                ? readFile('.jenkins/sql-review.log')
                                : 'No review output was produced.'
                            def reviewJson = fileExists('.jenkins/sql-review.json')
                                ? readFile('.jenkins/sql-review.json')
                                : 'No JSON output was produced.'

                            if (reviewOutput.size() > 12000) {
                                reviewOutput = reviewOutput.substring(reviewOutput.size() - 12000)
                            }
                            if (reviewJson.size() > 20000) {
                                reviewJson = reviewJson.substring(0, 20000) + '\n... output truncated ...'
                            }

                            def commentBody = """## Bytebase SQL Review — ${reviewStatus}

- Project: `${env.BYTEBASE_PROJECT}`
- Jenkins build: ${env.BUILD_URL ?: 'not available'}

<details><summary>Review output</summary>

```text
${reviewOutput}
```
</details>

<details><summary>Bytebase JSON details</summary>

```json
${reviewJson}
```
</details>
"""

                            writeFile(file: '.jenkins/sql-review-comment.md', text: commentBody)

                            withCredentials([
                                string(
                                    credentialsId: 'github-token',
                                    variable: 'GITHUB_TOKEN'
                                )
                            ]) {
                                sh '''#!/bin/sh
                                    set -eu

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
                                    jq -Rs '{body: .}' .jenkins/sql-review-comment.md > .jenkins/sql-review-comment.json
                                    http_status=$(curl --silent --show-error --retry 3 \\
                                      -X POST \\
                                      "$GITHUB_API_URL/repos/$repository/issues/$CHANGE_ID/comments" \\
                                      -H 'Accept: application/vnd.github+json' \\
                                      -H 'X-GitHub-Api-Version: 2022-11-28' \\
                                      -H "Authorization: Bearer $GITHUB_TOKEN" \\
                                      -H 'Content-Type: application/json' \\
                                      --data-binary @.jenkins/sql-review-comment.json \\
                                      --output .jenkins/github-comment-response.json \\
                                      --write-out '%{http_code}')
                                    cat .jenkins/github-comment-response.json
                                    test "$http_status" = '201'
                                '''
                            }
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
