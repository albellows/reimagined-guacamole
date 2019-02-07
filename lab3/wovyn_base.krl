ruleset wovyn_base {
  meta {
    use module twilio
    use module io.picolabs.subscription alias subs
  }

global {
    temperature_threshold = 75
    to_phone_number = "+13192109565"
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
      x{"temperatureF"} > sensor_profile:query{"temperature_threshold"}
    })) then
      send_directive("say", "High temp found")
    fired {
      raise wovyn event "threshold_violation" attributes event:attrs
    }
  }

  rule threshold_notification {
    select when wovyn threshold_violation
    twilio:send_sms(to_phone_number, from_phone_number, "High temperature!")
  }

}