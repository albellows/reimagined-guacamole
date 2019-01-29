ruleset twilio {
    meta {
        configure using account_sid = ""
                        auth_token = ""
        provides
            send_sms
    }

    global {
        send_sms = defaction(to, from, message) {
            base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
            http:post(base_url + "Messages.json", form= {
                "From":from,
                "To":to,
                "Body":message
            })
        }

        messages = function(page=0, page_size=50, to=null, from=null) {
            http:get(<<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json?Page=#{(page == null) => 0 | page}&PageSize=#{(page_size == null) => 50 | page_size}>> + ((to == null) => "" | <<&To=#{to}>>) + ((from == null) => "" | <<&From=#{from}>>)){"content"}.decode(){"messages"}
        }
    }
}