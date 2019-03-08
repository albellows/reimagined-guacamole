ruleset temperature_store {

    meta {
        provides temperatures, threshold_violations, inrange_temperatures
        shares temperatures, threshold_violations, inrange_temperatures
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