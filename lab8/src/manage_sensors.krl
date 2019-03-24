ruleset manage_sensors {
    meta {
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subs
        shares sensors, temperatures, latest_reports
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
        
        max = function(x) {
          x.sort("reverse").klog("reversed: ")[0]
        }

        latest_reports = function() {
            max = max(ent:reports.keys().klog("keys: ")).klog("max: ");

            ent:reports.defaultsTo({}).filter(function(v,k) {
                k > (max - 5)
            }).values()

        }

        temperatures = function() {

            sensors = sensor_subs().map(function(sensor) {
                {}.put(sensor{"Tx"}, sensor_ecis(){sensor{"Tx"}})
            }).klog("sensors: ");

            temps = sensors.map(function(sensor) {
              sensor.map(function(sensorInfo, eci) {
                  {}.put(wrangler:skyQuery(eci, "temperature_store", "temperatures", _host=sensorInfo{"host"}))
              })
            });
            temps
        }



    }

    rule request_reports {
        select when sensor request_reports
        foreach subs:established("Tx_role", "sensor") setting (sensor)
          pre {
              eci = sensor{"Tx"}
              rcn = ent:rcn.defaultsTo(0).klog("2")
              reports = ent:reports.defaultsTo({})
              originator_eci = sensor{"Rx"}
              num_sensors = ent:num_sensors.defaultsTo(0)
          }
          event:send({
              "eci" : eci.klog("about to send for eci: "),
              "eid" : 29,
              "domain" : "wovyn",
              "type" : "report_requested",
              "attrs": {
                  "originator_eci" : originator_eci,
                  "reporter_eci" : eci,
                  "rcn" : rcn
              }
          })
          always {
              ent:num_sensors := ent:num_sensors + 1;
              ent:reports{rcn} := {"temperature_sensors": num_sensors, "responding" : 0, "temperatures" : []} on final;
              ent:rcn := rcn + 1 on final;
              ent:num_sensors := null on final;
          }
    }

    rule report_recieved {
        select when sensor report
        pre {
            rcn = event:attr("rcn")
            temps = event:attr("temps")
            eci = event:attr("reporter_eci")
        }
        noop();
        always {
            ent:reports{[rcn, "responding"]} := ent:reports{[rcn, "responding"]} + 1;
            ent:reports{[rcn, "temperatures"]} := ent:reports{[rcn, "temperatures"]}.append([eci, temps]);
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
            // put the Wellknwon_Tx as the ECI
            ent:sensors{name} := { "eci": eci, "host": "http://localhost:8080" };
        }
    }

    // after wrangler has added a subscription, put subscription info in subscription entity variables
    rule subscription_added {
        select when wrangler subscription_added
        pre {
            eci = event:attr("Tx")
            host = event:attr("bus"{"Tx_host"}).defaultsTo("http://localhost:8080")
        }
        noop();
        always {
            ent:sensor_ecis{eci} := {"host": host}
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
        }
    }

    rule intialization {
        select when wrangler ruleset_added where rids >< meta:rid
        if ent:sensors.isnull() then noop();
        fired {
            ent:sensors := {};
            ent:sensor_ecis := {};
        }
    }



}



