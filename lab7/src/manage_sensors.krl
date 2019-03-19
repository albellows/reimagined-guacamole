ruleset manage_sensors {
    meta {
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subs
        shares sensors, temperatures
    }

    global {
        threshold = 78

        sensors = function() {
            ent:sensors
        }

        sensor_ecis = function() {
            ent:sensor_ecis
        }

        sensor_subs = function() {
            subs:established("Tx_role","sensor")
        }


        temperatures = function() {

            sensors = sensor_subs().klog("sensor:subs: ").map(function(sensor) {
                {}.put(sensor_ecis(){sensor[0]{"Tx"}}.klog("here is an eci: "))
            }).klog("sensors: ");

            temps = sensors.map(function(sensor, eci) {
                {}.put(wrangler:skyQuery(eci, "temperature_store", "temperatures", _host=sensor{"host"}))
            });
            temps
        }

    }

    rule create_sensor_pico {
        select when sensor new_sensor
        pre {
            name = event:attr("name")
            exists = ent:sensors >< name
        }
        if exists then send_directive("Sensor already exists");
        notfired {
            raise wrangler event "child_creation" attributes {
                "name": name,
                "rids": ["temperature_store", "wovyn_base", "sensor_profile", "io.picolabs.subscription", "auto_accept"]
            }

        }
    }

    rule ready_sensor_pico {
        select when wrangler child_initialized
        pre {
            eci = event:attr("eci")
            name = event:attr("name")
        }
        event:send({
            "eci": eci,
            "eid": "child_init",
            "domain": "sensor",
            "type": "profile_updated",
            "attrs": {
                "name": name,
                "threshold": threshold,
                "number": "+13192109565"
            }
        })
        always {
            raise wrangler event "subscription" attributes {
                "name" : name,
                "Rx_role" : "controller",
                "Tx_role" : "sensor",
                "channel_type" : "subscription",
                "wellKnown_Tx" : eci
            };
            ent:sensors{name} := { "eci": eci, "host": "http://localhost:8080" };
            ent:sensor_ecis{eci} := {"name": name, "host": "http://localhost:8080"};
        }
    }

    rule unneeded_sensor {
        select when sensor unneeded_sensor
        pre {
            name = event:attr("name")
            exists = ent:sensors >< name
        }
        if exists then send_directive("deleting child");
        fired {
            raise wrangler event "child_deletion" attributes {"name": name};
            ent:sensors := ent:sensors.delete(name)
        }
    }

    rule introduce_sensor {
        select when sensor introduce
        pre {
            eci = event:attr("eci")
            name = event:attr("name").klog("Name in introduce event: ")
            host = event:attr("host")
            exists = ent:sensors >< name
        }
        if exists then send_directive("Sensor already exists");
        notfired {
            raise wrangler event "subscription" attributes {
                "name" : name,
                "Rx_role" : "controller",
                "Tx_role" : "sensor",
                "channel_type" : "subscription",
                "wellKnown_Tx" : eci,
                "Tx_host" : host
            };
            ent:sensors{name} := { "eci" : eci, "host" : host };
            ent:sensor_ecis{eci} := {"name" : name, "host" : host };
        }
    }

    rule intialization {
        select when wrangler ruleset_added where rids >< meta:rid
        if ent:sensors.isnull() then noop();
        fired {
            ent:sensors := {}
        }
    }



}



