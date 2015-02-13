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

---

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

#### `find_and_activate`

The `find_and_activate` class level method will find the resource
provided in the email, retrieve the activation token, compare it against
the token and then activate the account. The calling code will then have
the opportunity to perform an action after the model is activated.

You can do the following if you do not want to do anything after a
successful activation:

```ruby
Model.find_and_activate(email, token)
```

This will mark the model attached to the email as being activated, clear
the activation token and it's expiration date.

You can also perform other actions after the model is successfully
activated. This could include anything from adding a flash message to
redirecting the user to a full registration page.

```ruby
Model.find_and_activate(email, token) do |model|
  Rails.logger.info("Activated #{model.inspect}")
end
```

### Activation Model Expectations

The model activation concern relies on the following columns in the
model:

```ruby
t.datetime :activated_at
t.string   :activation_token
t.datetime :activation_token_expires_at
```

It is recommended to and an unique index against the activation_token
column:

```ruby
add_index :users, :activation_token, name: 'idx_users_activation_token', unique: true
```

This will speed up queries against the activation token and enforce
uniqueness at the database level.

---

## Password Reset

### Password Reset Model Concern

Pillowfort provides the model level constructs to support password
resetting at the model level. This include creating and validating a
password reset token.

#### `create_password_reset_token`

This will create a password reset token and set it's expiration date.
The default expiration date is set to one hour from the creation of the
token. You can pick a different expiration date using the following
syntax:

```ruby
model.create_password_reset_token(expiry: 1.day.from_now)
```

#### `password_token_expired?`

Determines whether the password reset token has expired. A missing token
is considered to be expired.

#### `clear_password_reset_token`



#### `Model.find_and_validate_password_reset_token`

Retrieves the model associated with the email address provided and
validates the password reset token. It will yield the retrieved resource
to the provided block:

```ruby
Model.find_and_validate_password_reset_token(email, token) do |model|
  model.password = "new_password"
  model.save!
end
```

The calling code is responsible to either reset the password, perform
additional actions or to redirect the user to the password page if it
is required.

### Password Reset Model Expectations

The password reset concern expects the following fields to be set on the
model:

```ruby
t.string :password_reset_token
t.datetime :password_reset_token_expires_at
```

There should be an unique index on the `password_reset_token` column to
help with retrieving the model by the token and to ensure that the token
itself is unique:

```ruby
add_index :users, :password_reset_token, name: 'idx_users_pwd_reset_token', unique: true
```

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

