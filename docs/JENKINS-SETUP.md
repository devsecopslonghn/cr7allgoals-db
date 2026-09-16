# Jenkins setup

The repository is now driven by `Jenkinsfile`. GitHub remains the source-control
and pull-request system; Bytebase remains responsible for SQL Review, release
creation, database execution, and execution history.

## Job

Create a Jenkins Multibranch Pipeline pointing to:

```text
https://github.com/devsecopslonghn/cr7allgoals-db.git
```

Enable branch discovery and pull-request discovery. The pipeline stages are:

```text
Checkout → SQL Review (pull request only)
         → Create Rollout Plan (master only)
         → Rollout TEST (master only)
         → Rollout PROD (master only, approval required)
```

The `master` branch is the post-merge path. It targets Bytebase stage
`environments/test`, which is the configured DEV target for this POC.

## Jenkins credential

Create a **Username with password** credential with ID:

```text
bytebase-cr7-service-account
```

Set the username to the Bytebase service-account email and the password to its
service key. Do not put the Oracle username or password in Jenkins. Bytebase
holds the Oracle connection credential for the registered database.

Create a **Secret text** credential with ID:

```text
github-pr-comment-token
```

The token is used to post the SQL Review result to the GitHub pull request.

## Agent requirements

The Docker agent used by the pipeline needs:

- Docker Pipeline support and access to a Docker daemon;
- permission to pull `bytebase/bytebase-action:3.22.1`;
- network access to `https://bytebase.apps.drgdevlab.com`;
- permission to mount the Jenkins workspace into the action container;
- `git`, `curl`, `jq`, and `sed` available in the Bytebase action image.

If Jenkins runs on Kubernetes, provide an equivalent pod template with a
containerized Docker execution method, or adapt the `Jenkinsfile` to the
platform's approved Bytebase action runner. Do not grant the Jenkins agent
direct Oracle access for this pipeline.

## GitHub integration

Configure a GitHub webhook or Jenkins GitHub Branch Source integration so pull
requests trigger the review stage and merges to `master` trigger the release and
DEV rollout stages. Protect `master` and require the Jenkins check before merge.

The first successful DEV rollout was recorded before this conversion using the
former GitHub Actions runner. After Jenkins is configured, record the Jenkins
build URL and Bytebase release/plan in `docs/POC-EVIDENCE.md`.
