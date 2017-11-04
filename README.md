# env-nginx-proxy

You can set 3 environment variables. For example, if you want to proxy something like `http://app:3000`

`UPSTREAM_HOST`: The host to proxy (`app`)
`UPSTREAM_PORT`: The port to proxy (`3000`)
`PROTOCOL`: The protocol. It can be `HTTP` or `TCP`. By default it's `HTTP`

## Example

You can run this with something like:

```
$ docker run -d --link my-app-container:app --env UPSTREAM_HOST=app --env UPSTREAM_PORT=3000 -p 80:80 reyiyo/env-nginx-proxy
```

Or equivalent with docker-compose and other tools.