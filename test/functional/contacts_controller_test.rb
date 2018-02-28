require 'test_helper'

class ContactsControllerTest < ActionController::TestCase
  setup do
    @contact = contacts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:contacts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create contact" do
    assert_difference('Contact.count') do
      post :create, contact: { address_city: @contact.address_city, address_complement: @contact.address_complement, address_neighbourhood: @contact.address_neighbourhood, address_phone: @contact.address_phone, address_state: @contact.address_state, address_street: @contact.address_street, address_zip: @contact.address_zip, birth_date: @contact.birth_date, cell: @contact.cell, charge_city: @contact.charge_city, charge_complement: @contact.charge_complement, charge_neighbourhood: @contact.charge_neighbourhood, charge_phone: @contact.charge_phone, charge_state: @contact.charge_state, charge_street: @contact.charge_street, charge_zip: @contact.charge_zip, commerce_city: @contact.commerce_city, commerce_complement: @contact.commerce_complement, commerce_neighbourhood: @contact.commerce_neighbourhood, commerce_state: @contact.commerce_state, commerce_street: @contact.commerce_street, commerce_zip: @contact.commerce_zip, cpf: @contact.cpf, elector_title: @contact.elector_title, email: @contact.email, father: @contact.father, mother: @contact.mother, name: @contact.name, nationality: @contact.nationality, oab: @contact.oab, observations: @contact.observations, phone: @contact.phone, pis: @contact.pis, profession: @contact.profession, rg: @contact.rg, rg: @contact.rg, website: @contact.website, work_register: @contact.work_register }
    end

    assert_redirected_to contact_path(assigns(:contact))
  end

  test "should show contact" do
    get :show, id: @contact
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @contact
    assert_response :success
  end

  test "should update contact" do
    put :update, id: @contact, contact: { address_city: @contact.address_city, address_complement: @contact.address_complement, address_neighbourhood: @contact.address_neighbourhood, address_phone: @contact.address_phone, address_state: @contact.address_state, address_street: @contact.address_street, address_zip: @contact.address_zip, birth_date: @contact.birth_date, cell: @contact.cell, charge_city: @contact.charge_city, charge_complement: @contact.charge_complement, charge_neighbourhood: @contact.charge_neighbourhood, charge_phone: @contact.charge_phone, charge_state: @contact.charge_state, charge_street: @contact.charge_street, charge_zip: @contact.charge_zip, commerce_city: @contact.commerce_city, commerce_complement: @contact.commerce_complement, commerce_neighbourhood: @contact.commerce_neighbourhood, commerce_state: @contact.commerce_state, commerce_street: @contact.commerce_street, commerce_zip: @contact.commerce_zip, cpf: @contact.cpf, elector_title: @contact.elector_title, email: @contact.email, father: @contact.father, mother: @contact.mother, name: @contact.name, nationality: @contact.nationality, oab: @contact.oab, observations: @contact.observations, phone: @contact.phone, pis: @contact.pis, profession: @contact.profession, rg: @contact.rg, rg: @contact.rg, website: @contact.website, work_register: @contact.work_register }
    assert_redirected_to contact_path(assigns(:contact))
  end

  test "should destroy contact" do
    assert_difference('Contact.count', -1) do
      delete :destroy, id: @contact
    end

    assert_redirected_to contacts_path
  end
end
