ruleset manager_base {
    meta {
        use module manager_profile
        use module keys
        use module twilio
            with account_sid = keys:twilio{"account_sid"}
                 auth_token = keys:twilio{"auth_token"}
    }

    rule threshold_notification {
        select when manager threshold_violation
        twilio:send_sms(manager_profile:query(){"number"}, manager_profile:query(){"from_number"}, "High temperature!")
    }
}