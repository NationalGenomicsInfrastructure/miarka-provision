# Tarzan 

Ansible role for deploying the Kong (https://getkong.org/) API and microservice management layer. 

To be used for e.g. proxying other NGI pipeline web services and adding an authentication layer on top.

# Current status 

Kong, Cassandra and all other services gets installed correctly on the Irma cluster. 

- Kong uses Cassandra as storage engine. It listens on a couple of ports binded to localhost on irma1, and is launched through Uppsala's supervisord. 
- Kong itself spawns a modified nginx for the web stuff, and listens on localhost:8001 on irma1 for admin requests, and then globally on port 8888 for HTTP requests and port 4444 for HTTPS requests. Kong launched via Uppsala's crontab due to incompatibility with supervisord. 
- Kong spawns serf for cluster discovery, which listens to some ports binded to localhost at irma1. 
- Kong spawns dnsmasq that listens to some ports on irma1 for resolving DNS queries. 

At the moment there is no authentication required for Cassandra nor Kong's admin interface. But those ports are only available via localhost on irma1. 

There is no specific backup of Cassandra at the moment. And the serf traffic (over localhost) is not encrypted.  

# Usage 

## List all registered downstream APIs

To see all the downstream APIs that have been previously registered with the web proxy run the command ` curl -s http://localhost:8001/apis | python -m json.tool` on irma1. 

## Configuring self signed SSL cert

On irma1 run `openssl req -x509 -newkey rsa:2048 -keyout tarzan_key.pem -out tarzan_cert.pem -days 1460 -nodes -subj '/CN=irma1.uppmax.uu.se'` to generate a self signed server SSL key and cert for the webproxy running on irma1.uppmax.uu.se, which will be valid for 4 years. Put `tarzan_key.pem` and `tarzan_cert.pem` under `/lupus/ngi/irma3/deploy/files` so that they can be picked up by the Tarzan role. 

(One can then add the contents of `tarzan_cert.pem` to the client's CA bundle if one want to get rid of certificate warnings. E.g. some clients (like Stackstorm) use the Mozilla CA bundle in the Python library `requests`, which can usually be found under a path similar to `..../python2.7/site-packages/requests/cacert.pem`.)

## Adding a downstream API to Kong 

As an example, we will here demonstrate how to proxy the ngi_pipeline web API for Uppsala, as well as adding an authentication layer on top. 

Login to irma1 as user `funk_004`. Verify that Kong is started and listening on its admin interface by running `curl http://localhost:8001`. It should respond back with a long JSON payload. Also verify that Uppsala's ngi_pipeline web API is listening with e.g. `curl http://localhost:6666`. 

Now add a downstream API to Kong with: 

```
(NGI)[funk_004@irma1 ~]$ curl -i -X POST --url http://localhost:8001/apis --data 'name=ngi_pipeline_upps' --data 'upstream_url=http://localhost:6666' --data 'request_path=/ngi_pipeline_upps' --data 'strip_request_path=true'
```

It should respond back with a header `HTTP/1.1 201 Created` and a JSON payload. This means that we should now be able to access the ngi_pipeline Uppsala API via `https://irma1.uppmax.uu.se:4444/ngi_pipeline_upps`, or on irma1 with: 

```
[funk_004@irma1 ~]$ curl -k https://localhost:4444/ngi_pipeline_upps
<html><title>404: Not Found</title><body>404: Not Found</body></html>
(NGI)[funk_004@irma1 ~]$ 
```

## Enable token authentication 

To enable token authentication for our newly created downstream API we will enable the key-auth plugin for `ngi_pipeline_upps`: 

```
(NGI)[funk_004@irma1 ~]$ curl -i -X POST --url http://localhost:8001/apis/ngi_pipeline_upps/plugins --data 'name=key-auth'
HTTP/1.1 201 Created
[.. more output ..]
```

Now when authentication is enabled we should get permission denied if we try to access our resource: 

```
(NGI)[funk_004@irma1 ~]$ curl -i -k https://localhost:4444/ngi_pipeline_upps
HTTP/1.1 401 Unauthorized
[.. more output .. ]
```

## Create a token for access to our downstream API 

Before we create our token we first have to add an user `snpseq` to Kong: 

```
(NGI)[funk_004@irma1 ~]$ curl -i -X POST --url http://localhost:8001/consumers --data 'username=snpseq'
HTTP/1.1 201 Created
```

Now we can create our token for `snpseq`: 

```
(NGI)[funk_004@irma1 ~]$ curl -i -X POST --url http://localhost:8001/consumers/snpseq/key-auth 
HTTP/1.1 201 Created
```

Part of the response will be a JSON payload containing a `key` field, which is our newly created token. Save this! 

We can now verify that this works by accessing our ngi_pipeline API and supply the token with a `apikey` argument (or HTTP header): 

```
(NGI)[funk_004@irma1 ~]$ curl -k https://localhost:4444/ngi_pipeline_upps/?apikey=SECRET-TOKEN
<html><title>404: Not Found</title><body>404: Not Found</body></html>
(NGI)[funk_004@irma1 ~]$ 
```

Voila!

## Configure access control for downstream API 

We can now authenticate ourself with our username `snpseq` and our private token. Now we want to add access control, so that other Kong users can't access our ngi_pipeline Uppsala API.  To do this we have to enable Kong's ACL plugin for the ngi_pipeline Uppsala API. This will let the Kong group `upps_users` access the API:  

```
(NGI)[funk_004@irma1 ~]$ curl -i -X POST http://localhost:8001/apis/ngi_pipeline_upps/plugins --data 'name=acl' --data 'config.whitelist=upps_users'
HTTP/1.1 201 Created
[ .. more output .. ]
```

Trying to access the downstream API with `snpseq`'s token would now yield in an error: 

```
(NGI)[funk_004@irma1 ~]$ curl -k https://localhost:4444/ngi_pipeline_upps/?apikey=SECRET-TOKEN
{"message":"You cannot consume this service"}
(NGI)[funk_004@irma1 ~]$ 
```

So we have to add the user `snpseq` to the group `upps_users`: 

```
(NGI)[funk_004@irma1 ~]$ curl -i -X POST http://localhost:8001/consumers/snpseq/acls --data 'group=upps_users'
HTTP/1.1 201 Created
[ .. more output .. ]
```

Now when this is done we will be able connect to the API as `snpseq`, but as no other user: 

```
(NGI)[funk_004@irma1 ~]$ curl -k https://localhost:4444/ngi_pipeline_upps/?apikey=SECRET-TOKEN
<html><title>404: Not Found</title><body>404: Not Found</body></html>
(NGI)[funk_004@irma1 ~]$ 
```
