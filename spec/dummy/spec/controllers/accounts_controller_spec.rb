require 'rails_helper'

describe AccountsController, :type => :controller do
  describe 'its response' do
    subject { response }

    context 'when authenticated' do
      let(:account) { FactoryGirl.create :account }
      before {
        account.activate!
        authenticate_with account
      }

      describe 'unprotected #index' do
        before { get :index }
        it { should have_http_status :success }
      end

      describe 'protected #show' do
        before { get :show, id: 1 }
        it { should have_http_status :success }
      end
    end

    context 'when not authenticated' do
      describe 'unprotected #index' do
        before { get :index }
        it { should have_http_status :success }
      end

      describe 'protected #show' do
        before { get :show, id: 1 }
        it { should have_http_status :unauthorized }
      end
    end

    context 'when not activated' do
      let(:account) { FactoryGirl.create :account }
      before { authenticate_with account }

      describe 'unprotected #index' do
        before { get :index }
        it { should have_http_status :success }
      end

      describe 'protected #show' do
        before { get :show, id: 1 }
        it { should have_http_status :forbidden }
      end
    end
  end

  describe 'its methods' do
    describe '#current_account' do
      it { should respond_to(:current_account) }

      context 'when authenticated' do
        let(:account) { FactoryGirl.create :account }
        before do
          authenticate_with account
          get :show, id: 1
        end

        it 'should return the account when current_account is called' do
          expect(subject.current_account).to eq(account)
        end
      end
    end
  end
end
