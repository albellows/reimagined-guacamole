ruleset temperature_store {

    meta {
        provides temperatures, threshold_violations, inrange_temperatures
        shares temperatures, threshold_violations, inrange_temperatures
    }

    global {
        temperatures = function() {
            ent:temp_store.defaultsTo([])
        }

        threshold_violations = function() {
            ent:viol_store.defaultsTo([])
        }

        inrange_temperatures = function() {
            temperatures().difference(threshold_violations())
        }


    }

    rule send_report {
        select when wovyn report_requested
        event:send({
            "eci" : event:attr("originator_eci"),
            "eid" : 30,
            "domain" : "sensor",
            "type" : "report",
            "attrs": {
                "reporter_eci" : event:attr("reporter_eci"),
                "rcn" : event:attr("rcn"),
                "temps" : temperatures()
            }
        })
    }

    rule collect_temperatures {
        select when wovyn new_temperature_reading
        always {
            ent:temp_store := temperatures().append({"temperature": event:attr("temperature")["temperatureF"], "timestamp": event:attr("timestamp")})
        }
    }

    rule collect_threshold_violations {
        select when wovyn threshold_violation
        always {
            ent:viol_store := threshold_violations().append(event:attr("temperature").map(function(x) {
                {"temperature": x{"temperatureF"}, "timestamp": event:attr("timestamp")}
            }))
        }
    }

    rule clear_temperatures {
        select when sensor reading_reset
        always {
            ent:temp_store := null;
            ent:viol_store := null
        }
    }
}