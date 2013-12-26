class AddNoTimeToWorkLogKind < ActiveRecord::Migration
  def change
    add_column :work_log_kinds, :notime, :boolean, :null => true, :default => 0
  end
end
