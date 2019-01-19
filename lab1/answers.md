# Allison Bellows
## Lab 1 Answers

> Ruleset URL: https://raw.githubusercontent.com/albellows/reimagined-guacamole/master/lab1/hello_world.krl

#1
---
I got the same result, except with slightly different txn_ids.  This is because the hello_world ruleset is registered on the **engine**, not one channel particularly, and the event didn't specify any special channel-related information, so the rule will run the same way on any channel it's sent to.  The txn_id differed because

#2
---
I got the following result:
```
{"error":"ECI not found: R18cngsz4W2rpbQ38MM9BB"}
```
So the rule did not execute.  It stopped processing after attempting to access the channel, because I specified the channel ID for a channel that no longer existed.  

#3
---
I got the following result:
```
{"directives":[]}
```
Additionally, the logger noted that no rules were added to the schedule.
This happened because only "echo" is specified as a domain in the ruleset, as given by the "echo" in the select statement, so the channel could not find the domain "echo".  Therefore it couldn't find the event type "hello", and returned an empty result.