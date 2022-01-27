# falcon-container-sensor-pull
Bash script to pull latest Falcon Container Sensor from the CrowdStrike Container Registry to your local docker images

Prerequisite: `jq`, `docker`

Requires users to first set `CID`, `CS_CLIENT_ID`, & `CS_CLIENT_SECRET` environment variables. Additionally set the `CS_REGION` variable if the user is not on US-1 Falcon Cloud.

You may also opt for N-1 or N-2 images by modifying the JQ query to `jq -r '.resources[1].name' | \` for N-1 and `jq -r '.resources[2].name' | \` for N-2 on line number #32.
