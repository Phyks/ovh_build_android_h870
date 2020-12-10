#!/bin/bash
set -e

# Install OVH orchestrator dependencies
python3 -m venv .venv
./.venv/bin/pip install -r requirements.txt

# Set up an OVH instance to run the build
printf "%s" "Waiting for OVH instance ..."
IP_ADDRESS=$(./.venv/bin/python3 -m ovh_orchestrator init)
while ! timeout 0.2 ping -c 1 -n ${IP_ADDRESS} &> /dev/null
do
    printf "%c" "."
done

# Run the build on the OVH instance
scp ./build_android.sh ubuntu@${IP_ADDRESS}:~
ssh -f ubuntu@${IP_ADDRESS} 'screen -S build -dm bash ./build_android.sh'

# Wait for build to complete
set +e
printf "%s" "Building ..."
until ssh ubuntu@${IP_ADDRESS} 'ls ~/BUILD_DONE'; do
    printf "%c" "."
done
set -e

# Fetch back the built images
rsync -azr --progress ubuntu@${IP_ADDRESS}:~/android/lineage/out/target/product/h870/\*.{zip,md5sum,img} .

# Purge the OVH instance
./.venv/bin/python3 -m ovh_orchestrator purge ${IP_ADDRESS}
