ruleset auto_accept {
    rule accept {
        select when wrangler inbound_pending_subscription_added
        pre {
            attributes = event:attrs().klog("subscription: ");
        }
        always {
            raise wrangler event "pending_subscription_approval"
                attributes attributes;
            log info "auto accepted subscription.";
        }
    }
}