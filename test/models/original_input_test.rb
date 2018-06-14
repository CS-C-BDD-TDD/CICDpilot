require 'test_helper'

class OriginalInputTest < ActiveSupport::TestCase
  def setup
    @orig_input1 = OriginalInput.create(
      mime_type: 'text/plain',
      raw_content: 'Some sample text',
      remote_object_id: 'NCCIC:TestName-0123456789',
      remote_object_type: 'StixPackage',
      uploaded_file_id: 1,
      guid: '0123456789',
      input_category: 'cat1',
      input_sub_category: 'cat2'
    )
  end
  
  def teardown
    @orig_input1 = nil
  end
  
  test "json serialization uses serializer" do
    js = @orig_input1.as_json
    assert_not_empty(js)
    
    # Verify fields that should be there actually are
    assert_not_nil(js['id'])
    assert_not_nil(js['remote_object_id'])
    assert_not_nil(js['remote_object_type'])
    assert_not_nil(js['created_at'])
    
    #Verify fields that should not be there actually are not
    assert_nil(js['mime_type'])
    assert_nil(js['raw_content'])
    assert_nil(js['uploaded_file_id'])
    assert_nil(js['guid'])
    assert_nil(js['input_category'])
    assert_nil(js['input_sub_category'])
  end
  
  test "source scope returns the SOURCE input" do
    raw_text = File.read('test/fixtures/files/package_no_confidence.xml')
    
    @orig_input1.input_category = "SOURCE"
    @orig_input1.input_sub_category = nil
    @orig_input1.raw_content = raw_text
    @orig_input1.save
    
    orig_input2 = OriginalInput.create(
      mime_type: 'text/plain',
      raw_content: raw_text,
      remote_object_id: 'NCCIC:TestName-0123456789',
      remote_object_type: 'StixPackage',
      uploaded_file_id: 1,
      guid: '0123456790',
      input_category: 'Upload',
      input_sub_category: 'Human Review Completed'
    )    
    orig_input3 = OriginalInput.create(
      mime_type: 'text/plain',
      raw_content: raw_text,
      remote_object_id: 'NCCIC:TestName-0123456789',
      remote_object_type: 'StixPackage',
      uploaded_file_id: 1,
      guid: '0123456791',
      input_category: 'Upload',
      input_sub_category: 'Sanitized'
    )
    
    oi_list = OriginalInput.where(uploaded_file_id: 1)
    assert_equal 3, oi_list.size
    
    oi_source = OriginalInput.where(uploaded_file_id: 1).source
    assert_not_nil oi_source
    assert_equal 'SOURCE', oi_source.input_category
    
    oi_actives = OriginalInput.where(uploaded_file_id: 1).active
    assert_equal 2, oi_actives.size
  end
end