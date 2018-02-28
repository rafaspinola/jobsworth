class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.string :name
      t.string :cell
      t.string :phone
      t.string :email
      t.string :cpf
      t.string :oab
      t.string :rg
      t.string :pis
      t.string :nationality
      t.string :work_register
      t.string :profession
      t.string :elector_title
      t.date :birth_date
      t.string :father
      t.string :mother
      t.string :website
      t.text :observations
      t.string :address_street
      t.string :address_complement
      t.string :address_neighbourhood
      t.string :address_zip
      t.string :address_city
      t.string :address_state
      t.string :address_phone
      t.string :charge_street
      t.string :charge_complement
      t.string :charge_neighbourhood
      t.string :charge_zip
      t.string :charge_city
      t.string :charge_state
      t.string :charge_phone
      t.string :commerce_street
      t.string :commerce_complement
      t.string :commerce_neighbourhood
      t.string :commerce_zip
      t.string :commerce_city
      t.string :commerce_state

      t.timestamps
    end
  end
end
