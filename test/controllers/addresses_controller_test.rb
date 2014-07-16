require_relative '../test_helper'

describe AddressesController do
  let(:address) { FactoryGirl.create :address }
  let(:referenced_address) { FactoryGirl.create :address, :referenced }
  let(:user) { address.user }

  describe 'GET ::new' do
    it 'should render addresse\'s new_template' do
      sign_in user
      get(:new, user_id: user.id)
      assert_response :success
      assert_template :new
    end
  end

  describe 'POST ::create' do
    it 'should create new address' do
      @address_attrs = FactoryGirl.attributes_for :address
      sign_in user
      assert_difference 'Address.count', 1 do
        post :create, user_id: user.id, address: @address_attrs
      end
    end
  end

  describe 'GET ::edit' do
    it 'should render addresse\'s edit_template' do
      sign_in user
      get :edit, user_id: user.id, id: address.id
      assert_response :success
      assert_template :edit
    end
  end

  describe 'PATCH ::update' do
    it 'should update address' do
      sign_in user
    end
  end

  describe 'GET ::show' do
    it 'should render addresse\'s show_template' do
      sign_in user
      get :show, user_id: user.id, id: address.id
      assert_response :success
      assert_template :show
    end
  end

  describe 'DELETE ::destroy' do
    it 'should delete an address from the database' do
      sign_in user
      assert_difference('Address.count', -1) do
        delete :destroy, user_id: user.id, id: address.id
      end
    end
    it 'should stash a referenced address from the database' do
      sign_in user
      assert_difference('Address.count', 0) do
        delete :destroy, user_id: referenced_address.user.id, id: referenced_address.id
      end
      referenced_address.reload.stashed?.must_equal true
    end
  end
end