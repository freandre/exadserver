# exadserver

This is a simple implementation of an ad server.

The server is calling an exconfserver to have informations about the target metadata. Currently, finite, infinite and geoloc target are enabled.

Each target type store information in an ETS store:
* finite: the store is organized by finite value => bitfield of ad configuration id
* infinite: the store used is the main one, looking specifically to the given ads configuration
* geoloc: a geohash is computed for each configuration

Finding a set of configuraiton is done by searching in index sequentially, begining with finite ones, infinite and finally geoloc.

TODO:
* Deal with update of a configuration
* Modify inifinite index to speed it up (add ets stor for inclusive values)  
