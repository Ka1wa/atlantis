#!/usr/bin/env bash

IFS=$'\n\t'

# start atlantis server in the background and wait for it to start
./atlantis server \
  --gh-user="$GITHUB_USERNAME" \
  --gh-token="$GITHUB_PASSWORD" \
  --data-dir="/tmp" \
  --log-level="debug" \
  --repo-allowlist="github.com/runatlantis/atlantis-tests" \
  --repo-config-json='{"repos":[{"id":"/.*/", "allowed_overrides":["apply_requirements","workflow"], "allow_custom_workflows":true}]}' \
  &> /tmp/atlantis-server.log &
sleep 2

echo "Started atlantis server"

# start ngrok in the background and wait for it to start
./ngrok http 4141 > /tmp/ngrok.log &
sleep 4

# find out what URL ngrok has given us
export ATLANTIS_URL=$(curl -s 'http://localhost:4040/api/tunnels' | jq -r '.tunnels[] | select(.proto=="http") | .public_url')

echo "ATLANTIS_URL is $ATLANTIS_URL"

# Now we can start the e2e tests
cd "${GITHUB_WORKSPACE}/e2e"
echo "Running 'make build'"
make build

echo "Running e2e test: 'make run'"
set +e
make run
if [[ $? -eq 0 ]]
then
  echo "e2e tests passed"
else
  echo "e2e tests failed"
  echo "atlantis logs:"
  cat /tmp/atlantis-server.log
  exit 1
fi
