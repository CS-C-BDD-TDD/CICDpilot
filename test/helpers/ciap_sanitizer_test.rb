require 'test_helper'

class CiapSanitizerTest < ActiveSupport::TestCase
  def setup
    @mapping1 = CiapIdMapping.create(before_id: 'test_uid1', after_id: 'test_uid2')
    @mapping2 = CiapIdMapping.create(before_id: 'NCCIC_uid1', after_id: 'NCCIC_uid2')
    @sanitizer = CiapSanitizer.new
  end
  
  def teardown
    @mapping1 = nil
    @mapping2 = nil
    @sanitizer = nil
  end
  
  test "existing before_id mapping found" do
    mapval1 = @sanitizer.sanitize('TestName', 'test_uid1')
    assert_equal('test_uid2', mapval1)
  end
  
  test "existing non-NCCIC after_id mapping created" do
    mapval1 = @sanitizer.sanitize('TestName', 'test_uid2')
    assert_match(/^NCCIC:TestName/, mapval1)
  end
  
  test "existing NCCIC after_id mapping found" do
    mapval1 = @sanitizer.sanitize('TestName', 'NCCIC_uid2')
    assert_equal('NCCIC_uid2', mapval1)
  end
  
  test "created id found on subsequent search" do
    mapval1 = @sanitizer.sanitize('TestName', 'test_uid3')
    assert_match(/^NCCIC:TestName/, mapval1)
    
    mapval2 = @sanitizer.sanitize('TestName', 'test_uid3')
    assert_equal(mapval2, mapval1)
  end
  
  test "all mapped ids are included in mappings member" do
    mapval1 = @sanitizer.sanitize('TestName', 'test_uid1')
    mapval2 = @sanitizer.sanitize('TestName', 'test_uid2')
    mapval3 = @sanitizer.sanitize('TestName', 'test_uid3')
    mapval4 = @sanitizer.sanitize('TestName', 'NCCIC_uid1')
    mapval5 = @sanitizer.sanitize('TestName', 'NCCIC_uid2')
    mapval6 = @sanitizer.sanitize('TestName', 'NCCIC_uid3')
    
    assert_equal(6, @sanitizer.mappings.length)
    assert_equal(mapval1, @sanitizer.mappings['test_uid1'][:after_id])
    assert_equal(mapval2, @sanitizer.mappings['test_uid2'][:after_id])
    assert_equal(mapval3, @sanitizer.mappings['test_uid3'][:after_id])
    assert_equal(mapval4, @sanitizer.mappings['NCCIC_uid1'][:after_id])
    assert_equal(mapval5, @sanitizer.mappings['NCCIC_uid2'][:after_id])
    assert_equal(mapval6, @sanitizer.mappings['NCCIC_uid3'][:after_id])
  end
end
