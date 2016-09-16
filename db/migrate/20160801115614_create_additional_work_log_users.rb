class CreateAdditionalWorkLogUsers < ActiveRecord::Migration
  def change
    create_table :additional_work_log_users do |t|
      t.references :work_log
      t.references :user

      t.timestamps
    end
    add_index :additional_work_log_users, :work_log_id
    add_index :additional_work_log_users, :user_id
  end
end
