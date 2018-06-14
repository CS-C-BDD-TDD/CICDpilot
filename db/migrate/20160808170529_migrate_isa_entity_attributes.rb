class MigrateIsaEntityAttributes < ActiveRecord::Migration
  class MIsaEntity < ActiveRecord::Base;self.table_name = :isa_entity_caches end

  def up
    add_column :isa_entity_caches, :access_groups, :string

    MIsaEntity.reset_column_information

    MIsaEntity.all.find_in_batches do |group|
      group.each do |isa|
        cui = isa.cs_cui
        shrgrp = isa.cs_shargrp

        if cui.present? && shrgrp.present?
          access_groups = cui + ', ' + shrgrp
        elsif cui.present? && shrgrp.blank?
          access_groups = cui
        elsif cui.blank? && shrgrp.present?
          access_groups = shrgrp
        else
          next
        end

        access_groups = (access_groups.split(", ") - %w(ISAC CDC CIKR IC LES INT DIB EIN)).join(', ')
        isa.access_groups = access_groups
        isa.save
      end
    end

    remove_column :isa_entity_caches, :cs_cui
    remove_column :isa_entity_caches, :cs_shargrp
  end

  def down

  end
end
