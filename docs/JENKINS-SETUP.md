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
         → Create Release and Plan (master only)
         → Rollout DEV (master only)
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

## Agent requirements

The agent selected by the pipeline label `docker` needs:

- Docker CLI and access to a Docker daemon;
- network access to `https://bytebase.apps.drgdevlab.com`;
- permission to mount the Jenkins workspace into the action container.

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
