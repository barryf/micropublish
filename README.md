# Micropublish

Micropublish is a [Micropub][] client that you can use to create, update,
delete and undelete content on your Micropub-enabled site.
A live install of Micropublish is running at [https://micropublish.net][mp]

<img align="right"
src="https://barryf.s3-eu-west-1.amazonaws.com/micropublish-demo.gif"
alt="Micropublish demo">

---

## Features

- Create, update, delete and undelete posts on your site.
- Templates for creating Notes, Articles, RSVPs, Bookmarks, Replies, Reposts
  and Likes.
- Use `x-www-form-urlencoded` (form-encoded) or JSON Micropub request methods.
- Preview the request that will be sent to your server before it's sent.
- Supports multiple values for URL properties (e.g. `in-reply-to[]`).
- Customize types, icons, defaults, ordering and required properties.
- Mobile-first. All views have been designed and optimized for mobile.
- JavaScript is not required and you can happily use Micropublish without it.
  The user interface is progressively enhanced when JavaScript is enabled.
- Full errors and feedback displayed from your endpoints.
- Supports the `post-status` property
  [proposed as a Micropub extension][post-status].

---

## Requirements

There are a number of requirements that your site's Micropub endpoint must meet
in order to work with Micropublish.

To learn more about setting up a Micropub
endpoint, read the
[Creating a Micropub endpoint][micropub-endpoint] page on the
[IndieWeb wiki][indieweb] and the latest [Micropub specification][micropub].

Below is what Micropublish expects from your server.


### Endpoint discovery

When you enter your site's URL and click "Sign in" Micropublish will attempt to
find three endpoints in either your site's HTTP response header or in its
HTML `<head>`:

- Authorization endpoint
- Token endpoint
- Micropub endpoint

Your site should expose these endpoints similar to the following examples.

HTTP response header links:

    Link: <https://indieauth.com/auth>; rel="authorization_endpoint"
    Link: <https://tokens.indieauth.com/token>; rel="token_endpoint"
    Link: <https://barryfrost.com/micropub>; rel="micropub"

HTML document `<head>` links:

    <link href="https://indieauth.com/auth" rel="authorization_endpoint">
    <link href="https://tokens.indieauth.com/token" rel="token_endpoint">
    <link href="https://barryfrost.com/micropub" rel="micropub">

### Authorization

Micropublish will attempt to authenticate you via [web sign-in][signin] using
your authorization endpoint. This ensures you are the owner of the site/domain
that you entered. A recommended way of setting this up is by delegating to
[IndieAuth.com][].

When you have succesfully signed in, Micropublish will attempt to
authorize via OAuth 2.0 against your server's token endpoint to obtain an
access token.

When signing in you must specify the scope Micropublish should request from
your endpoint depending on what features you support. With the `post` scope
only the post creation action will be available.
For the editing/deleting/undeleting functionality,
your site's Micropub endpoint must support `create`, `update`, `delete` and
`undelete`. These scopes will be requested from your token endpoint.

### Configuration

When authorized, Micropublish will attempt to fetch your Micropub configuration
from your Micropub endpoint using `?q=config`.

It expects to find your `syndicate-to` list with `uid` and `name` keys for each
syndication target. Any other properties are currently ignored.

    {
      "syndicate-to": [
        {
          "uid": "https://twitter.com/barryf",
          "name": "barryf on Twitter"
        }
      ]
    }

### Methods

Micropublish supports either `x-www-form-urlencoded` (form-encoded) or
JSON-encoded requests when creating new posts or deleting/undeleting posts.
You can specify which method your server accepts/prefers on the dashboard.

Note: as required in the Micropub specification, new articles and all updates
must be sent via the JSON method.

---

## Customize

You can customize the dashboard shortcuts, properties and defaults you prefer
via the `config/properties.json` configuration file.

- `known` is a list of the properties Micropublish currently understands.
  These are referenced in the application.
- `default` is a list of the properties which will be included in the form
  for all new posts.
- `types` is an ordered list of types (e.g. note, article and reply) which
  correspond to the icon shortcuts on the dashboard. You can specify a `name`,
  `icon` (from [Font Awesome][fa]), appropriate `properties` from the `known`
  list and which properties are `required` to send the request.

---

## Hosting

Feel free to use the live version at [https://micropublish.net][mp].
Alternatively, you can host Micropublish yourself.

I recommend running this on Heroku using the _Deploy to Heroku_ button.

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/barryf/micropublish)

If you host on your own server you will need to define the `COOKIE_SECRET`
environment variable. You should use a long, secure, (ideally) random string
to help secure data stored in the user's cookie.

---

## Bookmarklets

Drag these links to your bookmarks bar and you can quickly perform each action
on a page you are viewing, with the relevant properties already filled:

- <a class="badge" href="javascript:window.location='https://micropublish.net/edit?url='+encodeURIComponent(location.href);">✏︎ Edit</a>
- <a class="badge" href="javascript:window.location='https://micropublish.net/delete?url='+encodeURIComponent(location.href);">✖︎ Delete</a>
- <a class="badge" href="javascript:window.location='https://micropublish.net/undelete?url='+encodeURIComponent(location.href);">✔︎ Undelete</a>
- <a class="badge" href="javascript:window.location='https://micropublish.net/new/h-entry/reply?in-reply-to='+encodeURIComponent(location.href);">↩ Reply</a>
- <a class="badge" href="javascript:window.location='https://micropublish.net/new/h-entry/repost?repost-of='+encodeURIComponent(location.href);">♺ Repost</a>
- <a class="badge" href="javascript:window.location='https://micropublish.net/new/h-entry/like?like-of='+encodeURIComponent(location.href);">❤ Like</a>
- <a class="badge" href="javascript:window.location='https://micropublish.net/new/h-entry/rsvp?in-reply-to='+encodeURIComponent(location.href);">✔︎ RSVP</a>
- <a class="badge" href="javascript:window.location='https://micropublish.net/new/h-entry/bookmark?bookmark-of='+encodeURIComponent(location.href)+'&name='+encodeURIComponent(document.title);">✂ Bookmark</a>

The URLs are hard-coded to the [https://micropublish.net][mp] install so you
will need to update if you are hosting Micropublish yourself.

---

## Help

If you would like any help with setting up your Micropub endpoint, your best
option is to
[join the `#indieweb` channel][irc] on Freenode IRC.

For Micropublish specific help, [get in touch][bfcontact] and I'll be happy
to help.

To file any bugs or suggestions for Micropublish, please log an issue in the
[GitHub repo][repo]. If you wish to make any improvements please fork and send
a pull request through GitHub.


[micropub]: https://micropub.net
[indieauth.com]: https://indieauth.com
[micropub-endpoint]: https://indieweb.org/micropub-endpoint
[indieweb]: https://indieweb.org
[fa]: http://fontawesome.io/
[signin]: http://indieweb.org/How_to_set_up_web_sign-in_on_your_own_domain
[repo]: https://github.com/barryf/micropublish
[irc]: http://indieweb.org/IRC
[bf]: https://barryfrost.com
[bfcontact]: https://barryfrost.com/contact
[mp]: https://micropublish.net
[post-status]: https://indieweb.org/Micropub-extensions#Post_Status