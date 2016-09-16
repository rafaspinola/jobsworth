# coding: utf-8
class AlterWorkLogKinds < ActiveRecord::Migration
  def up
    change_description("Discussão Interna", "Briefing")
    change_description("Providencia externa", "Diligência")
    WorkLogKind.create(description: "Andamento Processual")
    WorkLogKind.create(description: "Audiência")
  end

  def down
    change_description("Briefing", "Discussão Interna")
    change_description("Diligência", "Providencia externa")
    WorkLogKind.find_by_description("Andamento Processual").destroy
    WorkLogKind.find_by_description("Audiência").destroy

  end

  def change_description(old_description, new_description)
    w = WorkLogKind.find_by_description(old_description)
    w.description = new_description
    w.save
  end
end
