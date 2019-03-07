#!/bin/bash

# get pico names from user
printf "\n||============== STARTING PICO SYSTEM TEST ==============||\n"
printf "This test will create three picos - one connected to a Wovyn sensor, and two headless picos (not connected to a physical sensor, but rather receive events from direct HTTP requests).  \n\nWhat would you like to name your picos?\n"
read -p "Name of real (sensor) pico: " name
read -p "Name of first headless pico: " name1
read -p "Name of second headless pico: " name2

# create "real" sensor pico (connected to real Wovyn sensor)
eci=`curl -s http://localhost:8080/sky/event/VVyVkhSzpNj6BXEWaeiJ5K/17/sensor/new_sensor?name=$name 2>&1 | grep -oP '(?<="eci":").*?(?=")'`

# prompt user to connect real Wovyn sensor, then continue
printf "\nPico $name has been created with ECI $eci !\n"
read -p "Point sensor to this ECI, then press [ENTER] to continue..."

# create headless sensor picos
eci1=`curl -s http://localhost:8080/sky/event/VVyVkhSzpNj6BXEWaeiJ5K/17/sensor/new_sensor?name=$name1 2>&1 | grep -oP '(?<="eci":").*?(?=")'`
eci2=`curl -s http://localhost:8080/sky/event/VVyVkhSzpNj6BXEWaeiJ5K/17/sensor/new_sensor?name=$name2 2>&1 | grep -oP '(?<="eci":").*?(?=")'`
printf "Headless picos $name1 and $name2 have been creatd with ECIs $eci1 and $eci2, respectively.\n"

# check profiles
printf "\n=======PROFILE INFO=======\n"
printf "Initial profile info:\n"
curl http://localhost:8080/sky/cloud/$eci/sensor_profile/query -w '\n'
curl http://localhost:8080/sky/cloud/$eci1/sensor_profile/query -w '\n'
curl http://localhost:8080/sky/cloud/$eci2/sensor_profile/query -w '\n'

# update profile for first sensor
printf "\nUpdating profile info for $name1 based on info in profileData.json file, which contains:\n"
cat profileData.json
printf "\n"
curl http://localhost:8080/sky/event/$eci1/20/sensor/profile_updated -d "`cat profileData.json`" -H "Content-Type: application/json"

# check profiles again to verify change
printf "\nUpdated profile info:\n"
curl http://localhost:8080/sky/cloud/$eci/sensor_profile/query -w '\n'
curl http://localhost:8080/sky/cloud/$eci1/sensor_profile/query -w '\n'
curl http://localhost:8080/sky/cloud/$eci2/sensor_profile/query -w '\n'

# send heartbeat events to headless sensors
printf "\nSending heartbeat events to $name1 and $name2 based on info in tempData.json file, which contains:\n"
cat tempData.json
printf "\n"
curl http://localhost:8080/sky/event/$eci1/5/wovyn/heartbeat -d "`cat tempData.json`" -H "Content-Type: application/json" -w '\n'
curl http://localhost:8080/sky/event/$eci2/5/wovyn/heartbeat -d "`cat tempData.json`" -H "Content-Type: application/json" -w '\n'

# get temps
printf "\n=======TEMPERATURE INFO=======\n"
printf "Getting all temperature stores:\n"
curl http://localhost:8080/sky/cloud/VVyVkhSzpNj6BXEWaeiJ5K/manage_sensors/temperatures -w '\n'

# delete one
printf "\nDeleting $name1 (RIP):\n"
curl http://localhost:8080/sky/event/VVyVkhSzpNj6BXEWaeiJ5K/18/sensor/unneeded_sensor?name=$name1 -w '\n'

# get temps
printf "\nGetting all temperature stores:\n"
curl http://localhost:8080/sky/cloud/VVyVkhSzpNj6BXEWaeiJ5K/manage_sensors/temperatures -w '\n'

# conclude
printf "\n\n||============== END OF PICO SYSTEM TEST ==============||\n"
