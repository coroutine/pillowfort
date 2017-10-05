---
# WARNING!

Use of this library is strongly discouraged, as many of the tests are now broken.

If you are looking for a simple, well tested gem for API auth, let me recommend [Knock](https://github.com/nsarno/knock)

---

# Pillowfort

[![Build Status](https://travis-ci.org/coroutine/pillowfort.svg?branch=master)](https://travis-ci.org/coroutine/pillowfort)

Pillowfort is a opinionated, no bullshit, session-less authentication engine for Rails APIs. If you want a lot of configurability, get the fuck out. If you want lightweight, zero-config authentication for your API, you've come to the right place.

Pillowfort is nothing more than a handful of concerns, bundled up for distribution and reuse. It has absolutely no interest in your application. All it cares about is token management. How you integrate Pillowfort's tokens into your application is entirely up to you. You are, presumably, paid handsomely to make decisions like that.

You may find yourself wiring up controller and view code and thinking to yourself, *I wonder if Pillowfort has a method for handling this thing I find tedious*. Now ask yourself whether the functionality you want is related to token creation, retrieval, or validation.  If not, please allow us to spare everyone some trouble and assure you right now that Pillowfort gives exactly zero fucks about that thing you're doing. Godspeed.

Here's the break down:

![Pillowfort](docs/assets/pillowfort.gif)


## Basic Principles

Pillowfort has been optimized for API clients, but it fundamentally works like any Rails application&mdash;credentials are exchanged for an expirable token that is provided on all subsequent requests.

A client application creates a user session with Pillowfort by providing a email and password that matches a known set of credentials in the database. (Pillowfort uses `scrypt` to digest passwords.) When a match is found, Pillowfort returns a random, expirable secret token to the client application.

On all subsequent requests, the client application provides the email and secret  token in the request header, which Pillowfort processes via basic HTTP authentication.

If your API has more than one client application, each can specify a custom `x-realm` header to instruct Pillowfort to create separate sessions. This will allow a user to be logged into more than one client application simultaneously.

If you don't like that outcome, you can use the same realm value everywhere and Pillowfort will log users out of one application when they log into the other.

As with all things Pillowfort, it's up to you.


## Model Concerns

### Pillowfort Resource

Pillowfort doesn't care what authenticable model your application uses, but unless you're some kind of weirdo, it'll be your `User` model.

At a minimum, you'll need to add the `Base` concern to enable session token management.

If you want to enable email confirmation of new resource records, you should include the `Activation` concern. If you want to enable the resetting of forgotten passwords, you should include the `PasswordReset` concern.

Here's a model with the kitchen sink.


``` ruby
# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email           :string           not null
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  udx_users_on_email  (email) UNIQUE
#

class User < ApplicationRecord

  #--------------------------------------------------------
  # Configuration
  #--------------------------------------------------------

  # callbacks
  before_validation :ensure_password, on: :create

  # mixins
  include Pillowfort::Concerns::Models::Resource::Base
  include Pillowfort::Concerns::Models::Resource::Activation
  include Pillowfort::Concerns::Models::Resource::PasswordReset


  #--------------------------------------------------------
  # Private Methods
  #--------------------------------------------------------
  private

  #========== CALLBACKS ===================================

  def ensure_password
    unless password_digest.present?
      reset_password
    end
  end

end
```

#### Class Methods

**authenticate_securely(email, secret, realm='application')**

Accepts the email, secret, and realm from the client and returns the associated Pillowfort resource (or a suitable error). If found, extends the expiry of the session token for the specified realm.

**find\_and\_authenticate(email, password, realm='application')**

Accepts the email, password, and realm from the client and returns the associated Pillowfort resource (or a suitable error). If found, creates a new session token for the specified realm.

#### Public Methods

**activated?**

Returns true in all cases. Is overridden by including the `Activation` concern.

**authenticate(unencrypted)**

Accepts an unencrypted password value from the client and uses `scrypt` to determine whether or not it matches the `password_digest` attribute.

**password=(unencrypted)**

Accepts an unencrypted password and uses `scrypt` to perform a one-way hashing of the value.

**password_confirmation=(unencrypted)**

Accepts an unencrypted password confirmation and stores it in an instance variable to facilitate validations.

**reset_password**

Sets the resource model password (and confirmation) to randomly generated token string.  Does not save the change to the model.

**reset_session!(realm='application')**

Resets the session token for the specified realm. Returns the new token secret value.


### Activation Concern

#### Class Methods

**find_by_activation_secret(email, secret)**

Accepts the email and activation token secret from the client and returns the associated Pillowfort resource (or a suitable error).

#### Public Methods

**activatable?**

Returns `true` if the resource model has a valid, unconfirmed activation token; otherwise, `false`.

**activated?**

Returns `true` if the resource model has a confirmed activation token; otherwise, `false`.

**confirm_activation!**

Marks the current activation token as confirmed and returns the resource model (or a suitable error). This method completes the activation process.

**require_activation!**

Sets a new activation token secret and returns the activation token. This method starts the activation process.


### PasswordReset Concern

#### Class Methods

**find_by_activation_secret(email, secret)**

Accepts the email and activation token secret from the client and returns the associated Pillowfort resource (or a suitable error).

#### Public Methods

**password_resettable?**

Returns `true` if the resource model has a valid, unconfirmed password reset token; otherwise, `false`.

**confirm_password_reset!**

Marks the current password reset token as confirmed and returns the resource model (or a suitable error). This method completes the password reset process.


**require_password_reset!**

Sets a new password reset token secret and returns the password reset token. This method starts the password reset process.

---

### Pillowfort Token

At its core, Pillowfort is a token manager. You need a table to hold the token records and a model to manage them.

Unless you've read the source code thoroughly and know what you're doing, we **strongly** recommend you accept the default migration and simply add the corresponding concern to the token model.

Don't be a busybody. Help us help you.

``` ruby
# == Schema Information
#
# Table name: pillowfort_tokens
#
#  id           :integer          not null, primary key
#  resource_id  :integer          not null
#  type         :string           default("session"), not null
#  secret       :string           not null
#  realm        :string           default("application"), not null
#  created_at   :datetime         not null
#  expires_at   :datetime         not null
#  confirmed_at :datetime
#
# Indexes
#
#  udx_pillowfort_tokens_on_rid_type_and_realm  (resource_id,type,realm) UNIQUE
#  udx_pillowfort_tokens_on_type_and_token      (type,token) UNIQUE
#

class PillowfortToken < ApplicationRecord

  #--------------------------------------------------------
  # Configuration
  #--------------------------------------------------------

  # mixins
  include Pillowfort::Concerns::Models::Token::Base

end
```

#### Public Methods

*These methods are documented for the sake of being thorough, but in truth, you likely will not use them. They exist mostly for the internal use of the Pillowfort resource model. Your code will likely only ever need to invoke methods on the Pillowfort resource.*

**confirm**

Sets the `confirmed_at` attribute but does not save the token model.

**confirm!**

Sets the `confirmed_at` attribute and also saves the token model.

**confirmed?**

Returns `true` if the token model has been confirmed; otherwise, `false`.

**expire**

Sets the `expires_at` attribute but does not save the token model.

**expire!**

Sets the `expires_at` attribute and also saves the token model.

**expired?**

Returns `true` if the token model is expired; otherwise, `false`.

**refresh!**

Extends the `expires_at` value by the configured TTL for the token model's type and saves the token model.

**reset!**

Sets a new `secret` value, resets all timestamps, and saves the token model.

**secure_compare(value)**

Accepts a secret passed from the client and determines whether or not it matches the `secret` attribute value. This comparison is relatively slow in an effort to confound certain kinds of timing attacks.



## Controller Concerns

### Application Controller

Pillowfort has a single controller concern that teaches your `ApplicationController` to stop being such a jerk and to be cool for once in its life.

The controller concern does pretty much exactly what you would expect the authentication controller to do.  It authenticates all actions by default; it understands how to use Rails' basic HTTP authentication methods to get the client's email and secret; it knows how to determine the specified realm; it knows how to pass all that wiz biz to the Pillowfort resource class; and it knows how to handle any errors that the whole process might throw.

``` ruby
class ApplicationController < ActionController::API

  #--------------------------------------------------
  # Configuration
  #--------------------------------------------------

  # mixins
  include Pillowfort::Concerns::Controllers::Base

  # helpers
  helper_method :current_user


  #--------------------------------------------------
  # Private Methods
  #--------------------------------------------------
  private

  def current_user
    pillowfort_resource
  end

end
```


## Sample Endpoints

### Sessions

In this example, the endpoint supports three session-related actions.

- `show`: Returns information on the current session.
- `create`: Constructs a new session token for the associated resource (i.e., signs in).
- `destroy`: Deletes the current session token for the associated resource (i.e., signs out).

Because no session token exists for the `create` action, we need to skip token secret authentication and instead perform password authentication.

``` ruby
module V1
  class SessionsController < ApplicationController

    #------------------------------------------------------
    # Configuration
    #------------------------------------------------------

    # callbacks
    skip_before_action :authenticate_from_resource_secret!, only: [:create]


    #------------------------------------------------------
    # Public Methods
    #------------------------------------------------------

    #========== READ ======================================

    def show; end


    #========== CREATE ====================================

    def create
      email = params[:email].to_s.strip
      pword = params[:password].to_s.strip
      realm = pillowfort_realm

      @pillowfort_resource = User.find_and_authenticate(email, pword, realm)

      render :show
    end


    #========== DESTROY ====================================

    def destroy
      pillowfort_session_token.reset!
      head :ok
    end

  end
end
```

### Activations

In this example, the endpoint supports two actions for ensuring actual people are using your API.

- `show`: Allows the client to verify the activation token before bothering to present a password change form.
- `create`: Processes the password change request and creates a new session (i.e., signs in).

Because no session token exists when these actions are invoked, we need to skip token secret authentication in favor of activation token lookups.

``` ruby
module V1
  class ActivationsController < ApplicationController

    #------------------------------------------------------
    # Configuration
    #------------------------------------------------------

    # callbacks
    skip_before_action :authenticate_from_resource_secret!


    #------------------------------------------------------
    # Public Methods
    #------------------------------------------------------

    #========== READ ======================================

    def show
      email  = params[:email].to_s.strip
      secret = params[:secret].to_s.strip

      User.find_by_activation_secret(email, secret) do |resource|
        @user = resource
      end
    end


    #========== CREATE ====================================

    def create
      email  = params[:email].to_s.strip
      secret = params[:secret].to_s.strip

      User.transaction do
        User.find_by_activation_secret(email, secret) do |resource|
          @pillowfort_resource = resource
          @pillowfort_resource.attributes = create_params

          if @pillowfort_resource.save
            @pillowfort_resource.reset_session!(pillowfort_realm)
            @pillowfort_resource.confirm_activation!
          else
            render_unprocessable_error(@pillowfort_resource)
          end
        end
      end
    end


    #------------------------------------------------------
    # Private Methods
    #------------------------------------------------------
    private

    #========== PARAMS ====================================

    def create_params
      params.permit(
        :password,
        :password_confirmation
      )
    end

  end
end
```

### Password Requests

In this example, the endpoint supports a single action for the kind of person who has not yet heard of password managers.

- `create`: Accepts an email and locates the associated resource model. If found, a new password reset token is created and instructions are sent to the email address.

Because no session token exists when this action is invoked, we need to skip token secret authentication in favor of a simple email lookup.

``` ruby
module V1
  class PasswordRequestsController < ApplicationController

    #------------------------------------------------------
    # Configuration
    #------------------------------------------------------

    # callbacks
    skip_before_action :authenticate_from_resource_secret!


    #------------------------------------------------------
    # Public Methods
    #------------------------------------------------------

    #========== CREATE ====================================

    def create
      if user.persisted?
        user.require_password_reset!
        PasswordRequestMailerJob.perform_later(user.id)
        head :ok
      else
        user.errors.add(:email, 'address is invalid or unrecognized.')
        render_unprocessable_error(user)
      end
    end


    #------------------------------------------------------
    # Private Methods
    #------------------------------------------------------
    private

    #========== HELPERS ===================================

    def user
      @user ||= begin
        email = params[:email].to_s.strip.downcase
        User.where(email: email).first_or_initialize
      end
    end

  end
end
```

### Password Resets

In this example, the endpoint supports two actions for allowing users to regain control of their accounts.

- `show`: Allows the client to verify the password reset token before bothering to present a password change form.
- `create`: Processes the password change request and creates a new session (i.e., signs in).

Because no session token exists when these actions are invoked, we need to skip token secret authentication in favor of password reset token lookups.

``` ruby
module V1
  class PasswordResetsController < ApplicationController

    #------------------------------------------------------
    # Configuration
    #------------------------------------------------------

    # callbacks
    skip_before_action :authenticate_from_resource_secret!


    #------------------------------------------------------
    # Public Methods
    #------------------------------------------------------

    #========== GET =======================================

    def show
      email  = params[:email].to_s.strip
      secret = params[:secret].to_s.strip

      begin
        User.find_by_password_reset_secret(email, secret) do |resource|
          @user = resource
        end
      end
    end


    #========== CREATE ====================================

    def create
      email  = params[:email].to_s.strip
      secret = params[:secret].to_s.strip

      begin
        User.transaction do
          User.find_by_password_reset_secret(email, secret) do |resource|
            @pillowfort_resource = resource
            @pillowfort_resource.attributes = create_params

            if @pillowfort_resource.save
              @pillowfort_resource.reset_session!(pillowfort_realm)
              @pillowfort_resource.confirm_password_reset!
            else
              render_unprocessable_error(@pillowfort_resource)
            end
          end
        end
      end
    end


    #------------------------------------------------------
    # Private Methods
    #------------------------------------------------------
    private

    #========== PARAMS ====================================

    def create_params
      params.permit(
        :password,
        :password_confirmation
      )
    end

  end
end
```

## Configuration

Pillowfort comes preconfigured with sane defaults. But you may not like these values.

First, why are you being so mean? Second, you can override any of Pillowfort's default configurations in an initializer. The following example sets all available options to their default values:

``` ruby
Pillowfort.configure do |config|

  # classes
  config.resource_class               = :user
  config.token_class                  = :pillowfort_token

  # token lengths
  config.activation_token_length      = 40
  config.password_reset_token_length  = 40
  config.session_token_length         = 40

  # token ttls
  config.activation_token_ttl         = 7.days
  config.password_reset_token_ttl     = 7.days
  config.session_token_ttl            = 1.day

end
```


## Errors

Pillowfort throws three basic errors, which the controller concern automatically traps and routes to private handlers. By default, the handlers simply return an HTTP status of 401 (unauthorized). Like all things Rails, you are welcome to override the methods however you please.

The error handlers are:

``` ruby
# This method renders a standard response for resources
# that are not activated.
#
def render_pillowfort_activation_error
  head :unauthorized
end

# This method renders a standard response for resources
# that are not authenticated.
#
def render_pillowfort_authentication_error
  head :unauthorized
end

# This method renders a standard response for resources
# that attempt to modify tokens in illegal ways.
#
def render_pillowfort_token_state_error
  head :unauthorized
end
```


## FAQs

**I expect Pillowfort to do something, but I can't figure out the right method calls.**

Probably Pillowfort doesn't do the thing you expect. Pillowfort is tightly focused on a handful of authentication and token management functions. If a feature is not documented above, you can pretty safely assume it is not supported.

If that doesn't convince you, please peruse the `lib` directory at your leisure. Pillowfort is truly tiny and has been crafted lovingly by the capital fellows at Coroutine. Few experiences in your life will compare to the pleasure of reading our source code directly.

**I see that all the tests for this gem are hopelessly broken.**

Alas, that is true.  When Tim Lowrimore wrote the original version of Pillowfort, he provided a comprehensive set of probing, automated tests. Magical tests, really.

Some time later, John Dugan modified Pillowfort to allow for each resource to have multiple session tokens. At the time, he argued that he didn't have the bandwidth to rewrite the test suite, but the truth is he's a giant asshole.

In summary, please remember that Tim Lowrimore is a prince among men and John Dugan is your nemesis.

**This documentation is sort of absurd. I don't know if I can trust you clowns.**

These are excellent points, but Pillowfort is, we believe, well-designed and perfectly secure for most applications. We take our code very seriously; we take ourselves somewhat less so.

**None of these FAQs are actually questions.**

That's true. Thank you for actually reading this documentation. Your sacrifice shall be recorded in the Annuls of Ruby Heroes.


## Contributing

If you have an idea for improving Pillowfort, we would love to hear it. You are, no doubt, an expert in all things known and unknown in the universe, whereas we are mere mortals, toiling away at our data machines like so many monkeys at typewriters.

Having written that&mdash;it only took 1,000 years!&mdash;we suggest you open an issue on Github to discuss your idea with us before you haul off and author a PR.

Like Pillowfort, we are also opinionated.
