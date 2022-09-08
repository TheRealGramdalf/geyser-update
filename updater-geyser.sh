#!/bin/bash

# dependencies: curl, jq, echo, md5sum

####################################

########################## Jenkins configuration
# Main Jenkins domain
host="ci.opencollab.dev"

# Name of the job. Must not start or end with a slash(/)
# Make sure to include the job name as well as the branch
jobname="GeyserMC/job/Geyser/job/master"

# Name of jarfile. Will be appended to 'current-'
jar="geyser-spigot.jar"

# Download link
# Link to download new jarfile from
jarfile_url="https://ci.opencollab.dev/job/GeyserMC/job/Geyser/job/master/lastSuccessfulBuild/artifact/bootstrap/spigot/target/Geyser-Spigot.jar"

# Array of server UUIDs. Add your UUID surrounded by "double quotes"
# Each value must be separated by a space ' '
server_uuid=("466230cc-af70-4cb7-90e0-52abb23b5618" "a9cf636c-f3dd-45bf-8470-97de2dac343d")

# Volume path
# Path to the volume folder where pterodactyl stores the server volumes
# Must begin and end with a slash '/'
volpath="/var/lib/volumes/"


####################################


curlout="$(curl -g -s "https://$host/job/$jobname/lastSuccessfulBuild/api/json?depth=2&tree=fingerprint[fileName,hash]{1}")"

# Get the external hash from the curl output and print to terminal
external_hash="$(echo "$curlout" | jq -r '.fingerprint[0].hash')"
echo ""
echo "External hash is" "[""$external_hash""]"

# Get the internal curl hash using md5sum and print to terminal
internal_hash=$(md5sum current-"$jar" | cut -d ' ' -f 1)
echo "Internal hash is" "[""$internal_hash""]"
echo ""

if [ "$internal_hash" != "$external_hash" ]; then
    echo "Jarfile outdated. Downloading new file..."
    rm current-"$jar"
    curl -s -o current-"$jar" "$jarfile_url"
    for uid in "${server_uuid[@]}"
    do
        rm "$volpath""$uid"/plugins/"$jar"
        cp current-"$jar" "$volpath""$uid"/plugins/"$jar"
    done
else
    echo "Jarfile is up to date. Exiting..."
    exit 0
fi