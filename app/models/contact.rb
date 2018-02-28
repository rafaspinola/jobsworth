class Contact < ActiveRecord::Base

  default_scope order("updated_at desc")
  
  scope :search_name, lambda { |name| where("name like ?", "%#{name}%").order(:name)}

  def formatted_birth_date
    self.birth_date.strftime("%d/%m/%Y") unless self.birth_date == nil
  end

  attr_accessible :address_city, :address_complement, :address_neighbourhood, :address_phone, :address_state, :address_street, :address_zip, :birth_date, :cell, :charge_city, :charge_complement, :charge_neighbourhood, :charge_phone, :charge_state, :charge_street, :charge_zip, :commerce_city, :commerce_complement, :commerce_neighbourhood, :commerce_state, :commerce_street, :commerce_zip, :commerce_phone, :cpf, :elector_title, :email, :father, :mother, :name, :nationality, :oab, :observations, :phone, :pis, :profession, :rg, :rg, :website, :work_register, :category, :is_company, :is_person, :contact, :acronym, :phone2, :phone3, :marital_state, :client, :provider, :bond

end
