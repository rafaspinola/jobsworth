class RemoveResolutionTypes < ActiveRecord::Migration
  def up
  	Status.where("name like '%t fix%'").first.destroy
  	Status.where("name like '%invalid%'").first.destroy
  end

  def down
  	Status.create(company_id: 39892, name: "Invalid")
  	Status.create(company_id: 39893, name: "Won't fix")
  end
end
