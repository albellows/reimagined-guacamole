ruleset manager_profile {
    meta {
        use module keys
        use module twilio
            with account_sid = keys:twilio{"account_sid"}
                auth_token = keys:twilio{"auth_token"}

        provides query
        shares query
    }

    global {
        from_number = "+13197748556"

        query = function() {
            {
                "number": ent:number,
                "location": ent:location,
                "name": ent:name
            }
        }
    }

    rule profile_update {
        select when manager_profile update
        always {
            ent:number := event:attr("number").defaultsTo(ent:number);
        }
    }


    rule threshold_notification {
        select when manager threshold_violation
        twilio:send_sms(ent:number, from_number, "High temperature!")
    }

    rule initialization {
        select when wrangler ruleset_added where rids >< meta:rid
        if ent:number.isnull() then noop();
        fired {
            ent:number := "+13192109565";
        }
    }

}