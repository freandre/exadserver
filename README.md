# ExAdServerUmbrella

This is an umbrella project for a simple ad server.

Rougthly, the main piece, exadserver is using exconfserver to gather metadata informations about what is planned to target. The exjsonrpcserver acts as a frontend for the exadserver providing JSON RPC 2.0 over HTTP and TCP. A simple client, exjsonrpcclient can be used to test or bench the whole project.
