class AddColorToWorkLogKind < ActiveRecord::Migration
  def change
    add_column :work_log_kinds, :color, :string
  end
end
