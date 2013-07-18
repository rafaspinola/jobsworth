class AddKindToWorkLog < ActiveRecord::Migration
  def change
    add_column :work_logs, :kind, :integer
  end
end
