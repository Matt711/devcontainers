#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-creds-s3-persist [OPTION]...
#
# Set, unset, or reset the S3 bucket, region, and credentials in the environment.
#
# Boolean options:
#  -h,--help                      print this text
#  --no-bucket                    Unset the $SCCACHE_BUCKET environment variable for all shells.
#                                 (default: false)
#  --no-region                    Unset the $SCCACHE_REGION environment variable for all shells.
#                                 (default: false)
#
# Options that require values:
#  --stamp <stamp>                Timestamp when the S3 credentials were generated.
#                                 (default: none)
#  --bucket <bucket>              Set the $SCCACHE_BUCKET environment variable for all shells to <bucket> and persist in ~/.aws/config.
#                                 (default: none)
#  --region <region>              Set the $SCCACHE_REGION environment variable for all shells to <region> and persist in ~/.aws/config.
#                                 (default: none)
#  --aws-access-key-id <id>       Set the $AWS_ACCESS_KEY_ID environment variable for all shells to <id> and persist in ~/.aws/credentials.
#                                 (default: none)
#  --aws-session-token <token>    Set the $AWS_SESSION_TOKEN environment variable for all shells to <token> and persist in ~/.aws/credentials.
#                                 (default: none)
#  --aws-secret-access-key <key>  Set the $AWS_SECRET_ACCESS_KEY environment variable for all shells to <key> and persist in ~/.aws/credentials.
#                                 (default: none)

# shellcheck disable=SC1091
. "$(dirname "$(realpath -m "${BASH_SOURCE[0]}")")/../../update-envvars.sh";

_creds_s3_persist() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'creds-s3 creds-s3-persist';

    # Reset envvars
    reset_envvar "SCCACHE_BUCKET";
    reset_envvar "SCCACHE_REGION";
    reset_envvar "AWS_ACCESS_KEY_ID";
    reset_envvar "AWS_SESSION_TOKEN";
    reset_envvar "AWS_SECRET_ACCESS_KEY";

    mkdir -p ~/.aws;
    rm -f ~/.aws/{config,credentials};

    if test -n "${stamp:-}"; then
        echo "${stamp:-}" > ~/.aws/stamp;
    fi

    if ! grep -qE "^$" <<< "${no_bucket-}"; then
        unset_envvar "SCCACHE_BUCKET";
    elif ! grep -qE "^$" <<< "${bucket:-}"; then
        export_envvar "SCCACHE_BUCKET" "${bucket}";
        cat <<________EOF >> ~/.aws/config
bucket=${bucket:-}
________EOF
    fi

    if ! grep -qE "^$" <<< "${no_region-}"; then
        unset_envvar "SCCACHE_REGION";
    elif ! grep -qE "^$" <<< "${region:-}"; then
        export_envvar "SCCACHE_REGION" "${region}";
        cat <<________EOF >> ~/.aws/config
region=${region:-}
________EOF
    fi

    if test -f ~/.aws/config; then
        cat <<________EOF > ~/.aws/config2 && mv ~/.aws/config{2,}
[default]
$(cat ~/.aws/config)
________EOF
    fi

    if ! grep -qE "^$" <<< "${aws_access_key_id:-}"; then
        cat <<________EOF >> ~/.aws/credentials
aws_access_key_id=${aws_access_key_id}
________EOF
    fi

    if ! grep -qE "^$" <<< "${aws_secret_access_key:-}"; then
        cat <<________EOF >> ~/.aws/credentials
aws_secret_access_key=${aws_secret_access_key}
________EOF
    fi

    if ! grep -qE "^$" <<< "${aws_session_token:-}"; then
        cat <<________EOF >> ~/.aws/credentials
aws_session_token=${aws_session_token}
________EOF
    fi

    if test -f ~/.aws/credentials; then
        cat <<________EOF > ~/.aws/credentials2 && mv ~/.aws/credentials{2,}
[default]
$(cat ~/.aws/credentials)
________EOF
        chmod 0600 ~/.aws/credentials;
    fi
}

if [ "$(basename "${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}")" = devcontainer-utils-creds-s3-persist ]; then
    _creds_s3_persist "$@" <&0;
fi
