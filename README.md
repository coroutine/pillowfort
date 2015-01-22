# Pillowfort

Pillowfort is a very opinionated, no bullshit, session-less authentication engine for APIs.  If you want a lot of configurability, get the fuck out.  If you want lightweight, zero-config authentication for your API, you've come to the right place.

Pillowfort is nothing more that a couple of concerns, bundled up for distribution and reuse.  Here's the break down:

### Controller Authentication Concerns

The controller concern provides http basic authentication and access to a `current_user`, assuming authentication was successful.  In the event authentication fails, the concern simply returns a 401 response.

The controller concern also deletes the `WWW-Authenticate` header from the response.  Why the fuck would we do that?!  Here's why: if you're using something like Apache Cordova to build something like an iOS app that needs to authenticate against something like your API, this header is the bane of your existence.  You see, iOS will see the `WWW-Authenticate` header, do whatever the fuck it does with it and not pass it forward.  This means, there's no good way to handle the 401 response in your app, and do something smart, like redirecting the user to the login screen.

Lastly, by default, we setup the `before_filter` that authenticates each request to the API, when the controller concern is included into a controller.  You will likely want to skip this filter in you login controller.  This is how we do it:

    skip_filter :authenticate_from_account_token!, only: [:create]


### Model Authentication Concerns

The model concern provides token management logic.  This includes, token resets, token timeouts and password encryption.

This concern also provides a couple of class methods for checking the authenticity of a user's credentials:

- `authenticate_securely(email, token)` performs safe token authentication
- `find_and_authenticate` performs the initial password authentication, and returns the user, if authentication is successful.
