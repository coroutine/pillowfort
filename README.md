# Pillowfort

Pillowfort is a very opinionated, no bullshit, session-less authentication engine for Rails 4 APIs.  If you want a lot of configurability, get the fuck out.  If you want lightweight, zero-config authentication for your API, you've come to the right place.

Pillowfort is nothing more than a couple of concerns, bundled up for distribution and reuse.  Here's the break down:

![Pillowfort](docs/assets/pillowfort.gif)

## Authentication

### Controller Authentication Concerns

The controller authentication concern provides http basic authentication and access to a `current_#{model.class.name.underscore}`, assuming authentication was successful.  In the event authentication fails, the concern simply returns a 401 response.

The controller concern also deletes the `WWW-Authenticate` header from the response.  Why the fuck would we do that?!  Here's why: if you're using something like Apache Cordova to build something like an iOS app that needs to authenticate against something like your API, this header is the bane of your existence.  You see, iOS will see the `WWW-Authenticate` header, do whatever the fuck it does with it and not pass it forward.  This means, there's no good way to handle the 401 response in your app, and do something smart, like redirecting the user to the login screen.

Lastly, by default, we setup the `before_filter` that authenticates each request to the API, when the controller concern is included into a controller.  You will likely want to skip this filter in you login controller.  This is how we do it:

```ruby
skip_filter :authenticate_from_account_token!, only: [:create]
```

### Model Authentication Concerns

<hr/>

><h3>Notice!</h3>
  <p>
  Pillowfort requires `config.eager_load = true` in your development and test environments, as we need the authorization model to be loaded when the application loads.

<hr/>

The model concern provides the core authentication logic.  This includes, token resets, token timeouts and password encryption.

This concern also provides a couple of class methods for checking the authenticity of a user's credentials:

- `authenticate_securely(email, token)` performs safe token authentication
- `find_and_authenticate(email, password)` performs the initial password authentication, and returns the user, if authentication is successful.

#### Authentication Model Assumptions

Again, Pillowfort is opinionated, and in its opinion, you need the following fields defined on your model:

```ruby
t.string   "email",                 null: false
t.string   "password_digest",       null: false
t.string   "auth_token"
t.datetime "auth_token_expires_at"
```

## Activation

### Controller Activation Concern

The controller activation concern adds another layer of protection to
your API. It is dependent on the underlying
`current_#{model.class.name.underscore}` method added by the
authentication concern. It's whole purpose is to verify that the account
has been activated by the user. It returns a 403 response status code in
the event that the account has not been activated.

Here is how you add the activation concern to a controller:

```ruby
include Pillowfort::Concerns::ControllerActivation
```

The `enforce_activation!` filter is added by default by including the
`Pillowfort::ControllerActivation` concern into your controller. You can
exclude the filter from appropriate actions or controllers by skipping
it. This is how it is done:

```ruby
skip_filter :enforce_activation!, only: [:activate]
```

### Model Activation Concern

The model activation concern encapsulate the core activation logic. This
includes generating activation tokens, validating activation tokens,
recording when a user was activated at activation time.

You include the activation logic in the model via the
`Pillowfort::Concerns::ModelActivation` concern:

```ruby
include Pillowfort::Concerns::ModelActivation
```

This concerns adds the following activation related methods to the
model.

#### `create_activation_token`

`create_activation_token` will create and set the expiration date on
an activation token. The expiration date can be specified by passing
an `expiry` parameter like so:

```ruby
model.create_activation_token(expiry: 1.day.from_now)
```

The token and it's expiration date is then attached to the model.

#### `activation_token_expired?`

This method checks whether the activation token has expired. For our
purposes, a used activation token is considered to be expired.

#### `activated?`

Indicates whether the model has been activated.

#### `activated_at`

Stores when the model was activated.

#### `activate!`

Encapsulate the logic of activating a model.

---

## Examples

### An Authentication Controller

This is an example of how you might want to let user's login and logout:

```ruby
class Api::V1::AuthenticationsController < Api::ApplicationController
  skip_filter :authenticate_from_account_token!, only: [:create]

  def create
    @user = User.find_and_authenticate(
      authentication_params[:email],
      authentication_params[:password]
    )

    head :unauthorized unless @user
    # otherwise, render `create.json.jbuilder`
    # containing the auth_token.
  end

  def destroy
    current_user.reset_auth_token!
    head :ok
  end

  private

  def authentication_params
    params.permit(:email, :password)
  end
end
```

### The ApplicationController

To enable Pillowfort authentication, just include it in the appropriate controller:

```ruby
class ApplicationController < ActionController::API
  include Pillowfort::Concerns::ControllerAuthentication

  # ...
end
```

### The User Model (_...or whatever handles the auth record_)

```ruby
# == Schema Information
#
# Table name: users
#
#  id                    :integer          not null, primary key
#  email                 :string(255)      not null
#  password_digest       :string(255)      not null
#  auth_token            :string(255)
#  auth_token_expires_at :datetime
#  created_at            :datetime
#  updated_at            :datetime
#

class User < ActiveRecord::Base
  include Pillowfort::Concerns::ModelAuthentication
end
```

## Usage

Just add Pillowfort to your `Gemfile`, and include the concerns where appropriate (_see the examples above_).

```ruby
gem 'pillowfort'
```
