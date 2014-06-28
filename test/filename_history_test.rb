require 'minitest/autorun'
require 'minitest/spec'
require 'filename_history'

describe 'FileNameHistory test' do
  before do
    @filename_history = FileNameHistory.new 'test'
  end

  it 'has the same current and original name' do
    @filename_history.current.must_equal @filename_history.original
  end

  it 'has history of length 1' do
    @filename_history.history.must_be_instance_of Array
    @filename_history.history.length.must_equal 1
  end

  it 'must return a hash' do
    @filename_history.to_hash.must_be_instance_of Hash
  end

  it 'must not be changed' do
    @filename_history.changed?.must_equal false
  end

  it 'plans renames correctly' do
    @filename_history.plan_rename(/test/, 'tset')
    @filename_history.history.length.must_equal 2
    @filename_history.changed?.must_equal true
    @filename_history.was_named?('test').must_equal true
  end

  it 'plans rollbacks correctly' do
    @filename_history.plan_rename(/test/, 'tset')
    @filename_history.changed?.must_equal true
    @filename_history.plan_rollback
    @filename_history.changed?.must_equal false
    @filename_history.was_named?('tset').must_equal true
  end
end