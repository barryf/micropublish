**Micropublish encountered an error and cannot continue. Please read the help
information below, or [read the docs](/about) for more advice and examples
on getting set up.**

---

#### Missing or invalid value for "me": "{URL}".

You must specify a valid URL when logging in. The `me` value in the query string
was rejected.

Your URL must begin with `http://` or `https://`, e.g. `https://barryfrost.com`.

Passing just the domain isn't accepted, e.g. `barryfrost.com`.

---

#### Client could not connect to "{URL}".

Check the URL you have entered when logging in. Is it a public, valid URL?
Micropublish must be able to reach your URL over the internet.

- Is your URL private, e.g. `http://localhost/` or `http://127.0.0.1/`? If so
Micropublish cannot connect because your URL is not publcly available.

- If you have specified `https` and your domain's SSL certificate is not valid
then you will not be able to continue.

While testing, I recommend using [ngrok](https://ngrok.com/) to open a
tunnel to your device and expose a URL that Micropublish can see.

---

#### You must specify a valid scope.

Micropublish expects that the `scope` value is one of the following two options:

- `post`
- `create update delete undelete`

Please check the value you are passing in the query string.

---

#### Client could not find expected endpoints at {URL}.

No endpoints were found in either your server's response body or header.

You should specify the following values in either the header or body and
Micropublish will parse them.

- `micropub` -- your server's Micropub endpoint
- `authorization_endpoint` -- your authorization server, e.g.
   `https://indieauth.com/auth`
- `token_endpoint` -- your token server, e.g.
  `https://tokens.indieauth.com/token`

---

#### Client could not find {ENDPOINT} in body or header from {URL}"

One of the endpoints from the section above was missing when Micropublish
parsed your URL.

Please ensure that the endpoint is included in either your response header or
the body.

---

#### {CODE} status returned from {URL}.

An error code was received from your server when trying to discover your
endpoints.

Is your server publicly accessible and correctly responding to requests? There
may be an issue with your server that needs attention.
