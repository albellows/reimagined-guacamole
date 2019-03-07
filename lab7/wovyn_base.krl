ruleset wovyn_base {
  meta {
    use module sensor_profile
    use module keys
    use module io.picolabs.subscription alias subs
  }

global {
    from_phone_number = "+13197748556"
  }

  rule process_heartbeat {
    select when wovyn heartbeat
    if (event:attr("genericThing") != null) then
      send_directive("say", {})
    fired {
      raise wovyn event "new_temperature_reading" attributes {
        "temperature": event:attr("genericThing"){"data"}{"temperature"},
        "timestamp": time:now()
      }
    }
  }

rule find_high_temps {
    select when wovyn new_temperature_reading
    if (event:attr("temperature").any(function(x){
      x{"temperatureF"} > (sensor_profile:query(){"threshold"}).klog("threshold: ")
    })) then
      send_directive("say", {"something": "High temp found"})
    fired {
      raise wovyn event "threshold_violation" attributes event:attrs
    }
  }

  rule threshold_notification {
    select when wovyn threshold_violation
    pre {
      manager = subs:established("Tx_role", "controller").first();
    }
    event:send({
      "eci" : manager{"Tx"},
      "eid" : "threshold_violation",
      "domain" : "manager",
      "type" : "threshold_violation",
      "attrs" : event:attrs
    })
  }

}