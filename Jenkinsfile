// Keep SQL Review rendering in Jenkins so the result is portable across
// GitHub, GitLab, and any other SCM connected to this multibranch job.
def bytebaseHtml(value) {
    if (value == null) {
        return '-'
    }
    return value.toString()
        .replace('&', '&amp;')
        .replace('<', '&lt;')
        .replace('>', '&gt;')
        .replace('"', '&quot;')
        .replace("'", '&#39;')
        .replace('\r\n', '<br>')
        .replace('\n', '<br>')
}

def bytebaseRiskLevel(value) {
    switch (value?.toString()) {
        case 'LOW':
            return '🟢 Low'
        case 'MODERATE':
            return '🟡 Moderate'
        case 'HIGH':
            return '🔴 High'
        default:
            return '⚪ None'
    }
}

def buildBytebaseReviewSummary(String reviewJson, String project, String buildUrl) {
    // readJSON is a Jenkins Pipeline step and is sandbox-compatible. Returning
    // plain maps/lists also keeps the rest of this function easy to inspect.
    def payload = readJSON(text: reviewJson, returnPojo: true)
    def checkResults = payload instanceof Map && payload.checkResults instanceof Map ? payload.checkResults : [:]
    def results = checkResults.results instanceof List ? checkResults.results : []
    def details = []
    int errors = 0
    int warnings = 0

    results.each { result ->
        def advices = result?.advices instanceof List ? result.advices : []
        advices.each { advice ->
            def status = advice?.status?.toString() ?: 'UNKNOWN'
            if (status == 'ERROR') {
                errors++
            } else if (status == 'WARNING') {
                warnings++
            }

            if (status == 'ERROR' || status == 'WARNING') {
                def position = advice?.startPosition instanceof Map ? advice.startPosition : [:]
                def line = position.line != null ? position.line : (position.lineNumber ?: '-')
                details.add([
                    file: result?.file,
                    line: line,
                    severity: status == 'ERROR' ? '❌ Error' : '⚠️ Warning',
                    code: advice?.code,
                    title: advice?.title,
                    content: advice?.content,
                    target: result?.target
                ])
            }
        }
    }

    def summary = new StringBuilder()
    summary.append('# Bytebase SQL Review\n\n')
    summary.append("- Project: <code>${bytebaseHtml(project)}</code>\n")
    if (buildUrl?.trim()) {
        summary.append("- Jenkins build: ${buildUrl}\n")
    }
    summary.append("- Total affected rows: <b>${bytebaseHtml(checkResults.affectedRows ?: 0)}</b>\n")
    summary.append("- Overall risk level: <b>${bytebaseRiskLevel(checkResults.riskLevel)}</b>\n")
    summary.append("- Advice statistics: <b>${errors} Error(s), ${warnings} Warning(s)</b>\n\n")
    summary.append('## Advice details\n\n')

    if (details.isEmpty()) {
        summary.append('No warning or error advice was returned.\n')
        return summary.toString()
    }

    summary.append('<table><thead><tr><th>File</th><th>Line</th><th>Severity</th><th>Code</th><th>Title</th><th>Details</th><th>Target</th></tr></thead><tbody>\n')
    details.each { detail ->
        summary.append('<tr>')
        summary.append("<td><code>${bytebaseHtml(detail.file)}</code></td>")
        summary.append("<td>${bytebaseHtml(detail.line)}</td>")
        summary.append("<td>${bytebaseHtml(detail.severity)}</td>")
        summary.append("<td><code>${bytebaseHtml(detail.code)}</code></td>")
        summary.append("<td>${bytebaseHtml(detail.title)}</td>")
        summary.append("<td>${bytebaseHtml(detail.content)}</td>")
        summary.append("<td><code>${bytebaseHtml(detail.target)}</code></td>")
        summary.append('</tr>\n')
    }
    summary.append('</tbody></table>\n')
    return summary.toString()
}

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
                BYTEBASE_CREDENTIALS = credentials('bytebase-cr7-service-account')
            }
            steps {
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

                    if (fileExists('.jenkins/sql-review.json')) {
                        def summary = buildBytebaseReviewSummary(
                            readFile('.jenkins/sql-review.json'),
                            env.BYTEBASE_PROJECT,
                            env.BUILD_URL ?: ''
                        )
                        writeFile(
                            file: '.jenkins/bytebase-review-summary.md',
                            text: summary
                        )
                        echo summary
                    }

                    if (reviewStatus != 0) {
                        currentBuild.result = 'FAILURE'
                    }
                }
                archiveArtifacts(
                    artifacts: '.jenkins/sql-review.json,.jenkins/bytebase-review-summary.md',
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
