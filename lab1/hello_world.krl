ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Allison Bellows"
    logging on
    shares hello, monkey, __testing
  }
  
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }

    monkey = function(name) {
      msg = (name) => "Hello " + name | "Hello Monkey";
      //monkey_name = name.defaultsTo("Monkey").klog("our passed in name: ");
      //msg = "Hello " + monkey_name;
      msg
    }
    clear_name = { "_0": {"name": { "first": "GlaDOS", "last": ""} } }

    name = function(id) {
      all_users = users();
      nameObj = id => all_users{[id, "name"]}
                    | { "first": "HAL", "last": "9000"};
      first = nameObj{"first"};
      last = nameObj{"last"};
      first + " " + last
    }

    users = function() {
      ent:name
    }

    __testing = { "queries": [ { "name": "hello", "args": [ "obj" ] },
                              { "name": "monkey", "args": [ "name" ]},
                              { "name": "__testing" }],
                  "events": [ { "domain": "echo", "type": "hello" ,
                                "attrs": [ "id" ] },
                              { "domain": "echo", "type": "monkey" ,
                                "attrs": [ "name" ] },
                              { "domain": "hello", "type": "name", 
                                "attrs": [ "id", "first_name", "last_name" ] },
                              { "domain": "echo", "type": "hello"},
                              { "domain": "hello", "type": "clear"} ]
                }
  }

  rule hello_monkey {
    select when echo monkey

    pre {
      name = (event:attr("name") => event:attr("name") | "Monkey").klog("our passed in name: ")
      //name = event:attr("name").defaultsTo("Monkey").klog("our passed in name: ")
    }
    send_directive("say", {"something": "Hello " + name})
  }
  
  rule hello_world {
    select when echo hello

    pre {
      id = event:attr("id") || "_0"
      name = name(id)
      visits = ent:name{[id, "visits"]}.defaultsTo(0)
    }
    send_directive("say", {"something": "Hello " + name})
    fired {
      ent:name := ent:name.put([id, "visits"], visits + 1)
    }
  }

  rule store_name {
    select when hello name
    pre {
      passed_id = event:attr("id").klog("our passed in id: ")
      passed_first_name = event:attr("first_name").klog("our passed in first_name: ")
      passed_last_name = event:attr("last_name").klog("our passed in last_name: ")
    }
    send_directive("store_name", {
      "id" : passed_id,
      "first_name" : passed_first_name,
      "last_name" : passed_last_name
    })
    always {
      ent:name := ent:name.defaultsTo(clear_name, "initialization was needed");
      ent:name := ent:name.put([passed_id, "name", "first"], passed_first_name)
                          .put([passed_id, "name", "last"], passed_last_name)

    }
  }

  rule clear_names {
    select when hello clear
    always {
      ent:name := clear_name
    }
  }
  
}