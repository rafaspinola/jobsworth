class AddFieldsToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :category, :string
    add_column :contacts, :is_company, :boolean
    add_column :contacts, :is_person, :boolean
    add_column :contacts, :contact, :string
    add_column :contacts, :acronym, :string
    add_column :contacts, :phone2, :string
    add_column :contacts, :phone3, :string
    add_column :contacts, :marital_state, :string
    add_column :contacts, :client, :boolean
    add_column :contacts, :provider, :boolean
    add_column :contacts, :bond, :string
  end
end
