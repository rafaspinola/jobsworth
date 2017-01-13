class ClassifyTasks < ActiveRecord::Migration
  def up
    change_class(447047, 1)
    change_class(447052, 1)
    change_class(447054, 1)

    change_class(447061, 2)
    change_class(447055, 2)

    change_class(447048, 3)
    change_class(447059, 3)
    change_class(446992, 3)
    change_class(447050, 3)

    Tag.create(company_id: 39892, name: 'Registral', kind: 3)
    Tag.create(company_id: 39892, name: 'Administrativo', kind: 3)
    Tag.create(company_id: 39892, name: 'Urbanistico', kind: 3)
  end

  def down
    change_class(447047, nil)
    change_class(447052, nil)
    change_class(447054, nil)

    change_class(447061, nil)
    change_class(447055, nil)

    change_class(447048, nil)
    change_class(447059, nil)
    change_class(446992, nil)
    change_class(447050, nil)

    Tag.where("name = 'Registral'").first.destroy
    Tag.where("name = 'Administrativo'").first.destroy
    Tag.where("name = 'Urbanistico'").first.destroy
  end

  def change_class(id, kind)
    t = Tag.find(id)
    t.kind = kind
    t.save
  end
end
