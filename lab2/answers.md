# Allison Bellows </br> Lab 2 Answers

### **Module/ruleset URLs**

[Twilio module](https://raw.githubusercontent.com/albellows/reimagined-guacamole/master/lab2/twilio.krl) 
[Test ruleset](https://raw.githubusercontent.com/albellows/reimagined-guacamole/master/lab2/use_twilio.krl)

---
### **#1**

I would use a different module if it should have different authorized users.  For example, if I led a team where some members have full access to Sharepoint credentials and other members have full access to AWS credentials, I would make 2 separate modules for the AWS and Sharepoint keys.  I would also use different modules in the possible case of a name clash - since there is a single namespace for keys, if two keys need to have the same name, they should be in two separate key modules that are never loaded together.  

### **#2**

Because sending an SMS message *changes the state* of the API.  Actions request changes in state, so send_message is an action.  Functions don't request changes in state (they are typically GET requests), and since get_messsages is just a GET request that *doesn't* change the API state, get_messages is a function.