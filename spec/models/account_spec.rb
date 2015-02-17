require 'rails_helper'

# ------------------------------------------------------------------------------
# Shared Examples
# ------------------------------------------------------------------------------

RSpec.shared_examples 'an auth token resetter' do
  describe 'its affect on the auth_token' do
    subject { account.auth_token }

    describe 'before the call' do
      it { should eq(auth_token) }
    end

    describe 'after the call' do
      before { call_the_method }
      it { should_not eq(auth_token) }
    end
  end

  describe 'its affect on the auth_token_expires_at' do
    subject { account.auth_token_expires_at }

    describe 'before the call' do
      it { should eq(auth_token_expires_at) }
    end

    describe 'after the call' do
      before { call_the_method }
      it { should be > auth_token_expires_at }
    end
  end
end

# ------------------------------------------------------------------------------
# The Spec!
# ------------------------------------------------------------------------------

RSpec.describe Account, :type => :model do

  describe 'its validations' do
    before { account.save }
    subject { account.errors.messages }

    describe 'email validations' do
      let(:account) { FactoryGirl.build(:account, email: email) }

      context 'presence_of' do
        let(:email) { nil }

        it { should include(email: ["can't be blank"]) }
      end

      context 'uniqueness' do
        let(:email) { 'foobar@baz.com' }
        let(:dup_account) { FactoryGirl.build(:account, email: email) }
        before  { dup_account.save }
        subject { dup_account.errors.messages}

        it { should include(email: ["has already been taken"]) }
      end
    end

    describe 'password validations' do
      let(:account) { FactoryGirl.build(:account, password: password) }

      context 'presence_of' do
        let(:password) { nil }

        it { should include(password: [/can't be blank/, /is too short/]) }
      end

      context 'length of' do
        context "when it's too short" do
          let(:password) { "x"*3 }

          it { should include(password: [/is too short/])}
        end

        context "when it's too long" do
          let(:password) { "x"*80 }

          it { should include(password: [/is too long/])}
        end
      end

      describe 'activation validations' do
        let(:activation_token) { "my_token" }
        let(:activation_token_expires_at) { 1.hour.from_now }
        let(:activated_at) { nil }

        let(:account) {
          FactoryGirl.build(:account,
                            activation_token: activation_token,
                            activation_token_expires_at: activation_token_expires_at,
                            activated_at: activated_at
                           )
        }

        before { account.save }
        subject { account.errors.messages }

        it { should be_empty }

        context 'all fields set' do
          let(:activated_at) { 1.day.ago }

          it { should include( activation_token: [/must be blank/] ) }
          it { should include( activation_token_expires_at: [/must be blank/] ) }
          it { should include( activated_at: [/must be blank/] ) }
        end

        context 'no fields set' do
          let(:activation_token) { nil }
          let(:activation_token_expires_at) { nil }

          it { should include( activation_token: [/can't be blank/] ) }
          it { should include( activated_at: [/can't be blank/] ) }
        end

        context 'duplicate activation token' do
          let(:dup_account) {
            FactoryGirl.build(:account, activation_token: activation_token)
          }
          before { dup_account.save }
          subject { dup_account.errors.messages }

          it { should include activation_token: [/has already been taken/] }
        end
      end
    end
  end

  describe 'the instance methods' do
    let(:account) {
      FactoryGirl.create  :account,
                          auth_token: auth_token,
                          auth_token_expires_at: auth_token_expires_at,
                          password_reset_token: password_reset_token,
                          password_reset_token_expires_at: password_reset_token_expires_at,
                          activation_token: activation_token,
                          activation_token_expires_at: activation_token_expires_at
    }

    let(:auth_token) { 'abc123def456' }
    let(:auth_token_expires_at) { 1.day.from_now }
    let(:password_reset_token) { '123abc456def' }
    let(:password_reset_token_expires_at) { 1.hour.from_now }
    let(:activation_token) { 'activateme' }
    let(:activation_token_expires_at) { 1.hour.from_now }

    describe '#ensure_auth_token' do
      subject { account.auth_token }
      before { account.ensure_auth_token }

      context 'when the token is nil' do
        let(:auth_token) { nil }
        it { should_not be_nil }
      end

      context 'when the token is not nil' do
        let(:auth_token) { 'deadbeef' }
        it { should eq('deadbeef') }
      end
    end

    describe '#reset_auth_token' do
      let(:call_the_method) { account.reset_auth_token }
      it_behaves_like 'an auth token resetter'

      describe 'its persistence' do
        subject { account }
        after { call_the_method }
        it { should_not receive(:save) }
      end
    end

    describe '#reset_auth_token!' do
      let(:call_the_method) { account.reset_auth_token! }
      it_behaves_like 'an auth token resetter'

      describe 'its persistence' do
        subject { account }
        after { call_the_method }
        it { should receive(:save) }
      end
    end

    describe '#auth_token_expired?' do
      subject { account.auth_token_expired? }

      context 'when the token expiration is in the future' do
        let(:auth_token_expires_at) { 1.minute.from_now }
        it { should be_falsey }
      end

      context 'when the token expiration is in the past' do
        let(:auth_token_expires_at) { 1.minute.ago }
        it { should be_truthy }
      end
    end

    describe '#password=' do
      let!(:current_password) { account.password.to_s }
      subject { account.password.to_s }

      describe 'before the call' do
        it { should == (current_password) }
      end

      describe 'after the call' do
        before { account.password = 'fudge_knuckles_45' }
        it { should_not eq(current_password) }
      end
    end

    # ------------------------------------------------------------------------
    # Password reset tokens
    # ------------------------------------------------------------------------
    describe '#password_token_expired?' do
      subject { account.password_token_expired? }
      describe 'an unexpired token' do
        it { should be_falsey }
      end

      describe 'an expired token' do
        let(:password_reset_token_expires_at) { 1.hour.ago }
        it { should be_truthy }
      end
    end

   shared_examples_for 'password token creator' do
      describe '#password_reset_token' do
        subject { account.password_reset_token }
        it { should_not eq(password_reset_token) }
      end

      describe '#password_reset_token_expires_at' do
        subject { account.password_reset_token_expires_at }
        it { should_not eq(password_reset_token_expires_at) }
      end
    end

    describe '#create_password_reset_token with default expiration time' do
      before { account.create_password_reset_token }
      it_behaves_like 'password token creator'

      describe '#password_reset_token_expires_at' do
        subject { account.password_reset_token_expires_at }
        it { should be_within(5.seconds).of 1.hour.from_now }
      end
    end

    describe '#create_password_reset_token with specific expiration time' do
      before { account.create_password_reset_token(expiry: 10.minutes.from_now) }
      it_behaves_like 'password token creator'
      describe '#password_reset_token_expires_at' do
        subject { account.password_reset_token_expires_at }
        it {should be_within(5.seconds).of 10.minutes.from_now }
      end
    end

    describe '#clear_password_reset_token' do
      before { account.clear_password_reset_token }
      subject { account }
      its(:password_reset_token) { should be_blank }
      its(:password_reset_token_expires_at) { should be_blank }
      its(:password_token_expired?) { should be_truthy }
    end

    # ------------------------------------------------------------------------
    # Activation
    # ------------------------------------------------------------------------

    describe '#actived?' do
      subject { account }
      it { should_not be_activated }
      its(:activated_at) { should be_blank }
      its(:activation_token) { should eq(activation_token) }
      its(:activation_token_expires_at) { should eq(activation_token_expires_at) }
      its(:activation_token_expired?) { should be_falsey }

      context 'already activated' do
        before do
          subject.activate!
        end

        it { should be_activated }
        its(:activated_at) { should be_within(5.seconds).of Time.now }
        its(:activation_token) { should_not be_blank }
        its(:activation_token_expires_at) { should be_blank }
        its(:activation_token_expired?) { should be_truthy }
      end
    end

    describe '#create_activation_token' do
      subject { account }
      before { subject.create_activation_token }

      its(:activation_token) { should_not be_blank }
      its(:activation_token_expires_at) { should be_within(5.seconds).of 1.hour.from_now }
      its(:activation_token_expired?) { should be_falsey }

      context 'with specific expiration' do
        before { subject.create_activation_token(expiry: 5.minutes.from_now) }
        its(:activation_token_expires_at) { should be_within(5.seconds).of 5.minutes.from_now }
        its(:activation_token_expired?) { should be_falsey }
      end

      context 'with expiration in the past' do
        before { subject.create_activation_token(expiry: 10.minutes.ago) }
        its(:activation_token_expired?) { should be_truthy }
      end
    end
  end

  describe 'the class methods' do
    let(:email) { 'foobar@baz.com' }
    let(:token) { 'deadbeef' }
    let(:password) { 'admin4lolz' }
    let(:auth_token_expires_at) { 1.day.from_now }
    let(:activation_token) { 'activateme' }
    let(:activation_token_expires_at) { 1.hour.from_now }
    let(:password_reset_token) { 'resetme' }
    let(:password_reset_token_expires_at) { 1.hour.from_now }

    let!(:account) {
      FactoryGirl.create  :account,
                          email: email,
                          auth_token: token,
                          password: password,
                          auth_token_expires_at: auth_token_expires_at,
                          password_reset_token: password_reset_token,
                          password_reset_token_expires_at: password_reset_token_expires_at,
                          activation_token: activation_token,
                          activation_token_expires_at: activation_token_expires_at
    }

    describe '.authenticate_securely' do
      let(:email_param) { email }
      let(:token_param) { token }
      let(:block) { ->(resource) {} }

      subject { Account.authenticate_securely(email_param, token_param, &block) }

      context 'when email is nil' do
        let(:email_param) { nil }
        it { should be_falsey }
      end

      context 'when token is nil' do
        let(:token_param) { nil }
        it { should be_falsey }
      end

      context 'when email and token are provided' do

        context 'email case-sensitivity' do
          describe 'when an uppercased email address is provided' do
            let(:email_param) { email.upcase }

            it 'should yield the matched account' do
              expect { |b| Account.authenticate_securely(email_param, token_param, &b) }.to yield_with_args(account)
            end
          end

          describe 'when a downcased email address is provided' do
            let(:email_param) { email.downcase }

            it 'should yield the matched account' do
              expect { |b| Account.authenticate_securely(email_param, token_param, &b) }.to yield_with_args(account)
            end
          end
        end

        context 'when the resource is located' do

          context 'when the auth_token is expired' do
            let(:auth_token_expires_at) { 1.week.ago }

            it 'should reset the account auth_token' do
              allow(Account).to receive(:find_by_email_case_insensitive) { account }
              expect(account).to receive(:reset_auth_token!)
              subject
            end

            it { should be_falsey }
          end

          context 'when the auth_token is current' do

            context 'when the auth_token matches' do
              it 'should yield the matched account' do
                expect { |b| Account.authenticate_securely(email_param, token_param, &b) }.to yield_with_args(account)
              end
            end

            context 'when the auth_token does not match' do
              it { should be_falsey }
            end
          end
        end

        context 'when the resource is not located' do
          it { should be_falsey }
        end

      end
    end

    describe '.find_and_activate' do
      let(:email_param) { email }
      let(:token_param) { activation_token }
      let(:block) { ->(resource) {} }

      subject { Account.find_and_activate(email_param, token_param) }

      context 'when the resource is located' do
        context 'when the token matches' do
          it 'should activate the matched account' do
            expect_any_instance_of(Account).to receive(:activate!)
            subject
          end

          it 'should yield the matched account' do
            expect { |b| Account.find_and_activate(email_param, token_param, &b) }.to yield_with_args(account)
          end

          context "when the activation_token is expired" do
            let(:activation_token_expires_at) { 1.day.ago }
            it { should be_falsey }
          end
        end

        context "when the activation_token doesn't match" do
          let(:token_param) { 'notmytoken' }
          it { should be_falsey }
        end
      end

      context "when the email doesn't match" do
        let(:email_param) { 'notmyemail@gmail.com' }
        it { should be_falsey }
      end
    end

    describe '.find_and_validate_password_reset_token' do
      let(:email_param) { email }
      let(:token_param) { password_reset_token }
      subject { Account.find_and_validate_password_reset_token(email_param, token_param) }

      context "when the email doesn't match" do
        let(:email_param) { "bad_actor@gmail.com" }
        it { should be_falsey }
      end

      context "when the token doesn't match" do
        let(:token_param) { 'notmytoken' }
        it { should be_falsey }
      end

      it 'should yield the matched account' do
        expect { |b| Account.find_and_validate_password_reset_token(email_param, token_param, &b) }.to yield_with_args(account)
      end
    end

    describe '.find_and_authenticate' do
      let(:email_param) { email }
      let(:password_param) { password }

      subject { Account.find_and_authenticate(email_param, password_param) }


      context 'when the resource is located' do

        context 'when the password matches' do
          it { should eq(account) }
        end

        context 'when the password does not match' do
          let(:password_param) { "#{password}_bad" }
          it { should be_falsey }
        end
      end

      context 'when the resource is not located' do
        let(:email_param) { "#{email}_evil" }
        it { should be_falsey }
      end
    end
  end
end
