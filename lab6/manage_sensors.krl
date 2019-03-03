ruleset manage_sensors {
    meta {
        use module io.picolabs.wrangler alias wrangler
        shares sensors, temperatures
    }

    global {
        threshold = 75

        sensors = function() {
            ent:sensors
        }

        temperatures = function() {
            //names = ent:sensors.keys;
            temps = ent:sensors.map(function(eci, name) {
                wrangler:skyQuery(eci, "temperature_store", "temperatures").reduce(function(a,b) {b})
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
                "rids": ["temperature_store", "wovyn_base", "sensor_profile"]
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
            ent:sensors{event:attr("name")} := eci
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

    rule intialization {
        select when wrangler ruleset_added where rids >< meta:rid
        if ent:sensors.isnull() then noop();
        fired {
            ent:sensors := {}
        }
    }



}



