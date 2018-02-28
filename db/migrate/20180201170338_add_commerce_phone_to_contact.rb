class AddCommercePhoneToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :commerce_phone, :string
  end
end
