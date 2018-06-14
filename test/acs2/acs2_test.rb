require 'test_helper'

class Acs2Test < ActiveSupport::TestCase
  def setup
    setup_acs_records
  end

  # -- TLP Markings ----------------------------------------------------------

  test "Can add a TLP Marking Structure to a STIX Marking" do
    m = add_tlp_marking(@p2, 'AMBER')
    assert @p2.stix_markings(true).count == 1
    assert m.tlp_marking_structure(true)
  end

  # -- Simple Markings--------------------------------------------------------

  test "Can add a Simple Marking Structure to a STIX Marking" do
    m = add_simple_marking(@p2, 'When, in the course of human events...')
    assert @p2.stix_markings(true).count == 1
    assert m.simple_marking_structure(true)
  end

  private

    def setup_acs_records
      @p = StixPackage.create!(title: 'Package A')
      @p2 = StixPackage.create!(title: 'Package B')
    end

    def add_tlp_marking(obj, color)
      ms = TlpStructure.new(color: color)
      m = StixMarking.new(controlled_structure: "//node()", remote_object: obj)
      m.tlp_marking_structure = ms
      m.save
      m
    end

    def add_simple_marking(obj, statement)
      ms = SimpleStructure.new(statement: statement)
      m = StixMarking.new(controlled_structure: "//node()", remote_object: obj)
      m.simple_marking_structure = ms
      m.save
      m
    end
end
