# Contributing a Documentation Source

Each source documentation repository can notify this central library after a
successful publish.

## Required Variables in the Source Repository

Configure the following variables in the source repository's GitLab CI/CD
settings:

- `DOC_LIBRARY_TRIGGER_URL`: pipeline trigger URL for this repository
- `DOC_LIBRARY_TRIGGER_TOKEN`: pipeline trigger token for this repository
- `DOC_LIBRARY_TRIGGER_REF`: optional branch or tag in this repository to run

The source repository should submit these variables when triggering the central
pipeline:

- `DOC_SOURCE_PROJECT`: GitLab project path, such as `platform/payments-docs`
- `DOC_SOURCE_REF`: source branch or tag that was published
- `DOC_SOURCE_SHA`: commit SHA that produced the publish
- `DOC_SOURCE_URL`: optional published documentation URL
- `DOC_SOURCE_PIPELINE_URL`: optional source pipeline URL

## Optional Variables in This Repository

Set these variables if you want catalog updates to be committed back into this
repository automatically:

- `DOC_LIBRARY_PUSH_TOKEN`: token with permission to push to the default branch
- `DOC_LIBRARY_PUSH_USERNAME`: username to use for Git commits and pushes
- `DOC_LIBRARY_PUSH_EMAIL`: email to use for Git commits

Without push credentials, the pipeline will still validate and publish the site,
but catalog updates reported by trigger variables will not be persisted.
