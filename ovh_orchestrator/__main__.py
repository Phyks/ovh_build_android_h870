import uuid
import sys
import time

import ovh

from . import config


if __name__ == '__main__':
    client = ovh.Client(
        endpoint=config.ovh_endpoint,
        application_key=config.ovh_application_key,
        application_secret=config.ovh_application_secret,
        consumer_key=config.ovh_consumer_key,
    )

    if len(sys.argv) < 2:
        sys.exit(1)

    # Create VM
    if sys.argv[1] == 'init':
        # Get image id
        result = client.get(
            '/cloud/project/' + config.ovh_public_cloud_project + '/image',
            flavorType='s1-2',
            osType='linux',
            region=config.ovh_public_cloud_region,
        )
        image_id = next(
            x['id']
            for x in result
            if x['name'] == config.ovh_public_cloud_image
        )

        # Get SSH key id
        result = client.get(
            '/cloud/project/' + config.ovh_public_cloud_project + '/sshkey',
            region=config.ovh_public_cloud_region,
        )
        ssh_key_id = next(
            x['id']
            for x in result
            if x['name'] == config.ovh_public_cloud_sshkey_name
        )

        # Get flavor id
        result = client.get(
            '/cloud/project/' + config.ovh_public_cloud_project + '/flavor',
            region=config.ovh_public_cloud_region,
        )
        flavor_id = next(
            x['id']
            for x in result
            if x['name'] == 's1-2'
        )

        # Create instance
        name = str(uuid.uuid4())
        result = client.post(
            '/cloud/project/' + config.ovh_public_cloud_project + '/instance',
            flavorId=flavor_id,
            imageId=image_id,
            monthlyBilling=False,
            name=name,
            region=config.ovh_public_cloud_region,
            sshKeyId=ssh_key_id
        )

        if 'id' not in result:
            sys.exit(1)

        # Wait for IP address
        while True:
            result = client.get(
                '/cloud/project/' + config.ovh_public_cloud_project + '/instance',
                region=config.ovh_public_cloud_region,
            )
            ipAddresses = next(
                x['ipAddresses']
                for x in result
                if x['name'] == name
            )
            if ipAddresses:
                print(ipAddresses[0]['ip'])
                sys.exit(0)
            time.sleep(30)
    # Clear VM
    elif sys.argv[1] == 'purge':
        if len(sys.argv) < 3:
            sys.exit(1)

        # Get instance id from its IP address
        result = client.get(
            '/cloud/project/' + config.ovh_public_cloud_project + '/instance',
            region=config.ovh_public_cloud_region,
        )
        instance_id = next(
            x['id']
            for x in result
            if sys.argv[2] in x['ipAddresses']
        )

        # Delete instance
        client.delete(
            '/cloud/project/' + config.ovh_public_cloud_project +
            '/instance/' + instance_id
        )
    else:
        sys.exit(1)
