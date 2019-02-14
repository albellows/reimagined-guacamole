ruleset temperature_store {

    meta {
        provides temperatures, threshold_violation, inrange_temperatures
        shares temperatures, threshold_violation, inrange_temperatures
    }

    global {
        temperatures = function() {
            ent:temp_store
        }

        threshold_violations = function() {
            ent:viol_store
        }

        inrange_temperatures = function() {
            ent:temp_store.difference(ent:viol_store)
        }


    }

    rule test_temperatures {
        select when test temperatures
        send_directive("say", {"something" : temperatures()})
    }

    rule test_threshold_violations {
        select when test violations
        send_directive("say", {"something" : threshold_violations()})
    }

    rule test_inrange_temperatures {
        select when test inranges 
        send_directive("say", {"something" : inrange_temperatures()})
    }

    rule collect_temperatures {
        select when wovyn new_temperature_reading
        always {
            ent:temp_store := ent:temp_store.append(event:attr("temperature").map(function(x) {
                {"temperature": x{"temperatureF"}, "timestamp": event:attr("timestamp")}
            }))
        }
    }

    rule collect_threshold_violations {
        select when wovyn threshold_violation
        always {
            ent:viol_store := ent:viol_store.append(event:attr("temperature").map(function(x) {
                {"temperature": x{"temperatureF"}, "timestamp": event:attr("timestamp")}
            }))
        }
    }

    rule clear_temperatures {
        select when sensor reading_reset
        always {
            ent:temp_store := [];
            ent:viol_store := []
        }
    }
}