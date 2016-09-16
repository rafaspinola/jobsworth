class AddRiskToTask < ActiveRecord::Migration
  def up
  	change_table :tasks do |t|
    	t.references :risk_level, index: true
    	t.string :risk_value
      t.text :risk_justification
    end
  end

  def down
  	change_table :tasks do |t|
  		t.remove :risk_level_id
      t.remove :risk_value
      t.remove :risk_justification
  	end
  end
end
