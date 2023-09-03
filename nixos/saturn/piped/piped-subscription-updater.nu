#!/usr/bin/env nu
let base = $env.BASE
let token = (http post -t application/json $"($base)/login" {
  username: $env.USERNAME,
  password: $env.PASSWORD,
} | get token)

http get -H [Authorization $token] $"($base)/subscriptions"
  | get url 
  | each {|sub|
    http get $"($base)($sub)"
    sleep 1000ms
  }

exit 0
