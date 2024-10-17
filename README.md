# Webhook Action

This GitHub Action sends webhook requests based on specific branches (production
or release), with options to customize verbosity and silence output. The action
generates a unique request ID, gathers relevant GitHub event information, and
sends it as a JSON payload to the configured webhook URL. The action also
supports both SHA-1 and SHA-256 HMAC signatures for securing webhook requests.

## Inputs

| Input                | Description                                                                                                              | Default   | Required |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------ | --------- | -------- |
| `production_branch`  | The branch you consider your production branch.                                                                          | `main`    | No       |
| `release_branch`     | The branch you consider your release branch. If the current branch matches this input, the release webhook will be used. | `release` | No       |
| `webhook_production` | The webhook URL for the production environment.                                                                          | N/A       | Yes      |
| `webhook_release`    | The webhook URL for the release environment.                                                                             | N/A       | No       |
| `silent`             | Whether to suppress the output of the action.                                                                            | N/A       | No       |
| `verbose`            | Whether to enable verbose logging of the action's steps.                                                                 | N/A       | No       |

## Outputs

| Output          | Description                                        |
| --------------- | -------------------------------------------------- |
| `response-body` | The body of the response from the webhook request. |

## Example Usage

Here’s an example workflow configuration using this action:

```yaml
name: Webhook Deployment

on:
  push:
    branches:
      - main
      - release

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v2

      - name: Send Webhook to Production
        uses: your-repo/webhook-action@v1
        with:
          production_branch: 'main'
          webhook_production: ${{ secrets.WEBHOOK_PRODUCTION }}
          silent: false
          verbose: true

      - name: Send Webhook to Release
        if: github.ref == 'refs/heads/release'
        uses: your-repo/webhook-action@v1
        with:
          release_branch: 'release'
          webhook_release: ${{ secrets.WEBHOOK_RELEASE }}
          verbose: false
```

How It Works Webhook Selection:

The action checks whether the current branch is the production_branch or
release_branch. If the branch is the release branch and a release webhook URL is
provided, it sends the webhook to the release endpoint. Otherwise, it uses the
production webhook URL. Payload:

The webhook payload contains information about the event (event), repository,
commit SHA, reference, and the GitHub workflow details. A unique request ID
(requestID) is generated for each request. Signatures:

The payload is signed using both SHA-1 and SHA-256 HMAC signatures, using the
webhook URL as the secret key. Options:

You can control the verbosity of the logs by setting the verbose input to true.
This will print detailed curl command logs. Setting the silent input to true
will suppress output, but logs can still be reviewed in verbose mode. Response
Handling:

The response body from the webhook request is captured and outputted under the
response-body output. Security Ensure that sensitive information such as
webhook_production and webhook_release URLs are stored securely in GitHub
Secrets. Do not hardcode them in the workflow files.
