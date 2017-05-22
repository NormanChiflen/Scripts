{
"name": "riak-vagrant",
"default_attributes": {
},
"json_class": "Chef::Role",
"run_list": [
// These are all the Chef recipes that will be run. We want to
// configure the firewall, install riak and auto-join.
"recipe[iptables]",
"recipe[riak]",
"recipe[riak::iptables]",
"recipe[riak::autoconf]"
],
"description": "Role for firing up a Vagrant VM with Riak autoconfigured",
"chef_type": "role",
"override_attributes": {
"riak":{
"core":{
// This is optional, but helpful to distinguish from other clusters.
"cluster_name":"vagrant",
// This binds HTTP to all network interfaces
"http":[["0.0.0.0",8098]]
},
"kv":{
// This binds PBC to all network interfaces
"pb_ip":"0.0.0.0"
},
"package":{
// This makes sure we don't download the package every
// time. The SHA256 digest of the Debian i386 package.
"source_checksum":"dfe45da061bb530aba25fae831475bdf0473f778290c4e8f1947dc1bea63e246"
}
}
}
}