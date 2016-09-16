class CreateRiskLevels < ActiveRecord::Migration
  def up
    create_table :risk_levels do |t|
      t.string :description
    end

    RiskLevel.create(description: "Provavel")
    RiskLevel.create(description: "Possivel")
    RiskLevel.create(description: "Remoto")
  end

	def down
    drop_table :risk_levels
  end

end
