ruleset use_twilio {
  meta {
    use module keys
    use module twilio
      with account_sid = keys:twilio{"account_sid"}
           auth_token = keys:twilio{"auth_token"}

    shares test_send_sms, get_messages
  }

  rule test_send_sms {
    select when test new_message
      twilio:send_sms(event:attr("to").klog("to: "), event:attr("from").klog("from: "), event:attr("message").klog("msg: "))
  }

  rule get_messages {
    select when test get_messages
    send_directive("say", {"messages": twilio:messages(event:attr("page"), event:attr("page_size"), event:attr("to"), event:attr("from"))})
  }
}