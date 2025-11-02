set -euo pipefail
cd "$(dirname "$0")"

docker build . \
	--no-cache \
	-t maxo5499/sportsstack-api-gateway:latest
# docker push maxo5499/sportsstack-api-gateway:latest