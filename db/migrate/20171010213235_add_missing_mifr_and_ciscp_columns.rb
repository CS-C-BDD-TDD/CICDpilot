class AddMissingMifrAndCiscpColumns < ActiveRecord::Migration
  def change    
    add_column :vulnerabilities, :is_mifr, :boolean, :default => false
    add_column :vulnerabilities, :is_ciscp, :boolean, :default => false
    add_column :threat_actors, :is_mifr, :boolean, :default => false
    add_column :threat_actors, :is_ciscp, :boolean, :default => false    
    add_column :attack_patterns, :is_mifr, :boolean, :default => false
    add_column :attack_patterns, :is_ciscp, :boolean, :default => false            
  end
end
