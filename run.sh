#!/bin/bash
set -e
set -v

# Install OVH orchestrator dependencies
python3 -m venv .venv
./.venv/bin/pip install -r requirements.txt

# Set up an OVH instance to run the build
if [ "$1" == "" ] || [ $# -gt 1 ]; then
    printf "%s" "Waiting for OVH instance ..."
    IP_ADDRESS=$(./.venv/bin/python3 -m ovh_orchestrator init)
    echo " (IP: ${IP_ADDRESS}) "
    while ! timeout 0.2 ping -c 1 -n ${IP_ADDRESS} &> /dev/null
    do
        printf "%c" "."
        sleep 3
    done

    # Wait a bit to ensure SSH is up
    sleep 10

    # Run the build on the OVH instance
    scp -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" ./build_android.sh ubuntu@${IP_ADDRESS}:~
    # Build /e/ (or edit the BUILD_FLAVOR environment variable)
    ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -f ubuntu@${IP_ADDRESS} 'BUILD_FLAVOR=e screen -S build -dm bash ./build_android.sh'
else
    IP_ADDRESS="$1"
fi

# Wait for build to complete
set +e
printf "%s" "Building ..."
until ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" ubuntu@${IP_ADDRESS} 'ls ~/BUILD_DONE'; do
    printf "%c" "."
    sleep 30
done
set -e

# Fetch back the built images
#rsync -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" -azr --progress ubuntu@${IP_ADDRESS}:~/android/lineage/out/target/product/h870/\*.{zip,md5sum,img} out/

# Purge the OVH instance
./.venv/bin/python3 -m ovh_orchestrator purge ${IP_ADDRESS}
