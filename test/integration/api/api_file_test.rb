require 'test_helper'

class ApiFileTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of files" do
    file1 = CyboxFile.create!(file_name: 'file1.exe', file_name_condition: 'Equals', file_hashes_attributes:
                            [{hash_type: 'MD5', simple_hash_value: '12345678901234567890123456789012'},
                             {hash_type: 'SHA1', simple_hash_value: '1234567890123456789012345678901234567890'},
                             {hash_type: 'SHA256', simple_hash_value: '1234567890123456789012345678901234567890123456789012345678901234'},
                             {hash_type: 'SSDEEP', fuzzy_hash_value: 'ssdeepvalue'}])
    file2 = CyboxFile.create!(file_name: 'file2.exe', file_name_condition: 'StartsWith', file_hashes_attributes:
                            [{hash_type: 'MD5', simple_hash_value: '23456789012345678901234567890123'},
                             {hash_type: 'SHA1', simple_hash_value: '2345678901234567890123456789012345678901'},
                             {hash_type: 'SHA256', simple_hash_value: '2345678901234567890123456789012345678901234567890123456789012345'},
                             {hash_type: 'SSDEEP', fuzzy_hash_value: 'ssdeepvalue2'}])
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: file1)

    get("/files",nil,@headers)
    result = JSON.parse(response.body)['files']
    file_resp = result.second

    assert_json_file(file_resp,file1)
    assert_json_file(result.first,file2)
  end

  test "get single files" do
    file = CyboxFile.create!(file_name: 'file.exe', file_name_condition: 'Equals', file_hashes_attributes:
                           [{hash_type: 'MD5', simple_hash_value: '12345678901234567890123456789012'},
                            {hash_type: 'SHA1', simple_hash_value: '1234567890123456789012345678901234567890'},
                            {hash_type: 'SHA256', simple_hash_value: '1234567890123456789012345678901234567890123456789012345678901234'},
                            {hash_type: 'SSDEEP', fuzzy_hash_value: 'ssdeepvalue'}])
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: file)

    get("/files/#{file.cybox_object_id}",nil,@headers)
    file_resp = JSON.parse(response.body)

    assert_json_file(file_resp,file)

    ind_resp = file_resp['indicators'].first
    assert_json_indicator(ind_resp,indicator)
    assert !ind_resp.has_key?("observables")
  end

  test "create a file" do
    data = { file_name: 'file.exe', file_name_condition: 'Equals', file_hashes_attributes:
             [{hash_type: 'MD5', simple_hash_value: '12345678901234567890123456789012'},
              {hash_type: 'SHA1', simple_hash_value: '1234567890123456789012345678901234567890'},
              {hash_type: 'SHA256', simple_hash_value: '1234567890123456789012345678901234567890123456789012345678901234'},
              {hash_type: 'SSDEEP', fuzzy_hash_value: 'ssdeepvalue'}] }
    post "/files", data, @headers
    assert response.status == 200
    assert CyboxFile.count == 1
    assert_json_file(JSON.parse(response.body),CyboxFile.first)
  end

  test "pagination of files" do
    file1 = CyboxFile.create!(file_name: 'file1.exe', file_name_condition: 'Equals', file_hashes_attributes:
                            [{hash_type: 'MD5', simple_hash_value: '12345678901234567890123456789012'},
                             {hash_type: 'SHA1', simple_hash_value: '1234567890123456789012345678901234567890'},
                             {hash_type: 'SHA256', simple_hash_value: '1234567890123456789012345678901234567890123456789012345678901234'},
                             {hash_type: 'SSDEEP', fuzzy_hash_value: 'ssdeepvalue'}])
    file2 = CyboxFile.create!(file_name: 'file2.exe', file_name_condition: 'StartsWith', file_hashes_attributes:
                            [{hash_type: 'MD5', simple_hash_value: '23456789012345678901234567890123'},
                             {hash_type: 'SHA1', simple_hash_value: '2345678901234567890123456789012345678901'},
                             {hash_type: 'SHA256', simple_hash_value: '2345678901234567890123456789012345678901234567890123456789012345'},
                             {hash_type: 'SSDEEP', fuzzy_hash_value: 'ssdeepvalue2'}])

    get("/files?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['files']
    get("/files?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['files']

    assert_json_file(result1.first,file2)
    assert_json_file(result2.first,file1)
  end
end
