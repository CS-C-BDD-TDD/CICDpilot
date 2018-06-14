class CreateDnsQueryCyboxObject < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.table_exists?(:cybox_dns_queries)
      create_table :cybox_dns_queries do |t|
        t.string :guid
        t.string :cybox_hash
        t.string :cybox_object_id
        t.string :portion_marking
        t.string :question_normalized_cache
        t.string :answer_normalized_cache
        t.string :authority_normalized_cache
        t.string :additional_normalized_cache
        t.boolean :is_reference
        t.boolean :read_only, :default => false
        t.timestamps :null => true
      end
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:cybox_dns_queries, :guid)
      add_index :cybox_dns_queries, :guid
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:cybox_dns_queries, :cybox_object_id)
      add_index :cybox_dns_queries, :cybox_object_id
    end

    if !ActiveRecord::Base.connection.table_exists?(:questions)
      create_table :questions do |t|
        t.string :guid
        t.string :cybox_hash
        t.string :portion_marking
        t.string :qclass
        t.string :qtype
        t.string :qname_cache
        t.boolean :is_reference
        t.boolean :read_only, :default => false
        t.timestamps :null => true
      end
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:questions, :guid)
      add_index :questions, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:resource_records)
      create_table :resource_records do |t|
        t.string :guid
        t.string :cybox_hash
        t.string :portion_marking
        t.string :record_type
        t.string :dns_record_cache
        t.boolean :is_reference
        t.boolean :read_only, :default => false
        t.timestamps :null => true
      end
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:resource_records, :guid)
      add_index :resource_records, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:dns_query_resource_records)
      create_table :dns_query_resource_records do |t|
        t.string :dns_query_id
        t.string :resource_record_id
        t.string :guid
        t.string :user_guid
        t.timestamps :null => true
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:dns_query_resource_records, :dns_query_id)
      add_index :dns_query_resource_records, :dns_query_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:dns_query_resource_records, :resource_record_id)
      add_index :dns_query_resource_records, :resource_record_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:dns_query_resource_records, :guid)
      add_index :dns_query_resource_records, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:resource_record_dns_records)
      create_table :resource_record_dns_records do |t|
        t.string :resource_record_id
        t.string :dns_record_id
        t.string :guid
        t.string :user_guid
        t.timestamps :null => true
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:resource_record_dns_records, :resource_record_id)
      add_index :resource_record_dns_records, :resource_record_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:resource_record_dns_records, :dns_record_id)
      add_index :resource_record_dns_records, :dns_record_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:resource_record_dns_records, :guid)
      add_index :resource_record_dns_records, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:dns_query_questions)
      create_table :dns_query_questions do |t|
        t.string :dns_query_id
        t.string :question_id
        t.string :guid
        t.string :user_guid
        t.timestamps :null => true
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:dns_query_questions, :dns_query_id)
      add_index :dns_query_questions, :dns_query_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:dns_query_questions, :question_id)
      add_index :dns_query_questions, :question_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:dns_query_questions, :guid)
      add_index :dns_query_questions, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:question_uris)
      create_table :question_uris do |t|
        t.string :question_id
        t.string :uri_id
        t.string :guid
        t.string :user_guid
        t.timestamps :null => true
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:question_uris, :question_id)
      add_index :question_uris, :question_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:question_uris, :uri_id)
      add_index :question_uris, :uri_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:question_uris, :guid)
      add_index :question_uris, :guid
    end

  end
  
  def down
    if ActiveRecord::Base.connection.index_exists?(:cybox_dns_queries, :guid)
      remove_index :cybox_dns_queries, :guid
    end
    
    if ActiveRecord::Base.connection.index_exists?(:cybox_dns_queries, :cybox_object_id)
      remove_index :cybox_dns_queries, :cybox_object_id
    end
    
    if ActiveRecord::Base.connection.index_exists?(:questions, :guid)
      remove_index :questions, :guid
    end
    
    if ActiveRecord::Base.connection.index_exists?(:questions, :cybox_object_id)
      remove_index :questions, :cybox_object_id
    end
    
    if ActiveRecord::Base.connection.index_exists?(:resource_records, :guid)
      remove_index :resource_records, :guid
    end
    
    if ActiveRecord::Base.connection.index_exists?(:resource_records, :cybox_object_id)
      remove_index :resource_records, :cybox_object_id
    end

    if ActiveRecord::Base.connection.index_exists?(:dns_query_resource_records, :dns_query_id)
      remove_index :dns_query_resource_records, :dns_query_id
    end

    if ActiveRecord::Base.connection.index_exists?(:dns_query_resource_records, :resource_record_id)
      remove_index :dns_query_resource_records, :resource_record_id
    end

    if ActiveRecord::Base.connection.index_exists?(:dns_query_resource_records, :guid)
      remove_index :dns_query_resource_records, :guid
    end

    if ActiveRecord::Base.connection.index_exists?(:resource_record_dns_records, :resource_record_id)
      remove_index :resource_record_dns_records, :resource_record_id
    end

    if ActiveRecord::Base.connection.index_exists?(:resource_record_dns_records, :dns_record_id)
      remove_index :resource_record_dns_records, :dns_record_id
    end

    if ActiveRecord::Base.connection.index_exists?(:resource_record_dns_records, :guid)
      remove_index :resource_record_dns_records, :guid
    end

    if ActiveRecord::Base.connection.index_exists?(:dns_query_questions, :dns_query_id)
      remove_index :dns_query_questions, :dns_query_id
    end

    if ActiveRecord::Base.connection.index_exists?(:dns_query_questions, :question_id)
      remove_index :dns_query_questions, :question_id
    end

    if ActiveRecord::Base.connection.index_exists?(:dns_query_questions, :guid)
      remove_index :dns_query_questions, :guid
    end

    if ActiveRecord::Base.connection.index_exists?(:question_uris, :question_id)
      remove_index :question_uris, :question_id
    end

    if ActiveRecord::Base.connection.index_exists?(:question_uris, :uri_id)
      remove_index :question_uris, :uri_id
    end

    if ActiveRecord::Base.connection.index_exists?(:question_uris, :guid)
      remove_index :question_uris, :guid
    end

    if ActiveRecord::Base.connection.table_exists?(:cybox_dns_queries)
      drop_table :cybox_dns_queries
    end

    if ActiveRecord::Base.connection.table_exists?(:questions)
      drop_table :questions
    end

    if ActiveRecord::Base.connection.table_exists?(:resource_records)
      drop_table :resource_records
    end

    if ActiveRecord::Base.connection.table_exists?(:dns_query_resource_records)
      drop_table :dns_query_resource_records
    end

    if ActiveRecord::Base.connection.table_exists?(:resource_record_dns_records)
      drop_table :resource_record_dns_records
    end

    if ActiveRecord::Base.connection.table_exists?(:dns_query_questions)
      drop_table :dns_query_questions
    end

    if ActiveRecord::Base.connection.table_exists?(:question_uris)
      drop_table :question_uris
    end
  end
end
