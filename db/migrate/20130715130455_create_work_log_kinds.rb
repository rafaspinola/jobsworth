class CreateWorkLogKinds < ActiveRecord::Migration
  def change
    create_table :work_log_kinds do |t|
      t.string :description

      t.timestamps
    end
  end
end
