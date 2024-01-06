NC='\033[0m' # No Color
YELLOW='\033[1;33m'
RED='\033[0;31m'
LIGHT_BLUE='\033[1;34m'
GREEN='\033[0;32m'

log() {
	if [ -z "$1" ]; then
		echo
	else
		printf "${LIGHT_BLUE}==> $1${NC}\n"
	fi
}

warn() {
	if [ -z "$1" ]; then
		echo
	else
		printf "${YELLOW}=====> ${YELLOW}$1${NC}\n"
	fi
}

error() {
	if [ -z "$1" ]; then
		echo
	else
		printf "${RED}=====> $1${NC}\n"
	fi
}

step() {
	if [ -z "$1" ]; then
		echo
	else
		printf "${GREEN}=====> $1${NC}\n"
	fi
}

substep() {
	if [ -z "$1" ]; then
		echo
	else
		printf "${GREEN}========> $1${NC}\n"
	fi
}
