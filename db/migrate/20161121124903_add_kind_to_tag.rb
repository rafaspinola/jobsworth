class AddKindToTag < ActiveRecord::Migration
  def change
    add_column :tags, :kind, :integer
  end
end
