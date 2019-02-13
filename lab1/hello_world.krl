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

    __testing = { "queries": [ { "name": "hello", "args": [ "obj" ] },
                              { "name": "monkey", "args": [ "name" ]},
                              { "name": "__testing" }],
                  "events": [ { "domain": "echo", "type": "hello" ,
                                "attrs": [ "name" ] },
                              { "domain": "echo", "type": "monkey" ,
                                "attrs": [ "name" ] },
                              { "domain": "hello", "type": "name", 
                                "attrs": [ "name" ] },
                              { "domain": "echo", "type": "hello"}]
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
      name = event:attr("name").defaultsTo(ent:name, "use stored name").klog("our passed in name: ")
    }
    send_directive("say", {"something": "Hello World"})
  }

  rule store_name {
    select when hello name
    pre {
      name = event:attr("name").klog("our passed in name: ")
    }
    send_directive("store_name", {"name":name})
    always {
      ent:name := name
    }
  }
  
}