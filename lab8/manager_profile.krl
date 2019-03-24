ruleset manager_profile {
    meta {
        provides query
        shares query
    }

    global {
        from_number = "+13197748556"

        query = function() {
            {
                "number": ent:number,
                "location": ent:location,
                "name": ent:name,
                "from_number" : from_number
            }
        }
    }

    rule profile_update {
        select when manager_profile update
        always {
            ent:number := event:attr("number").defaultsTo(ent:number);
        }
    }


    rule initialization {
        select when wrangler ruleset_added where rids >< meta:rid
        if ent:number.isnull() then noop();
        fired {
            ent:number := "+13192109565";
            ent:location := "Provo";
            ent:name := "wovyn"
        }
    }

}