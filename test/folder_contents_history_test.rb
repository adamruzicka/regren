require 'minitest/autorun'
require 'minitest/spec'
require 'folder_contents_history'
require 'tmpdir'
require 'fileutils'

describe 'FolderContentsHistory test' do

  describe 'when no data is loaded' do
    before do
      @fch = FolderContentsHistory.new      
    end

    it 'is not changed' do
      @fch.changed.must_be_instance_of Hash
      @fch.changed.empty?.must_equal true
    end

    it 'has no conflicts' do
      @fch.changed.must_be_instance_of Hash
      @fch.changed.length.must_equal 0
    end

    it 'has empty hash as representation' do
      @fch.to_hash.must_be_instance_of Hash
      @fch.to_hash.empty?.must_equal true
    end

    it 'returns empty hash when planning' do
      hash = @fch.plan_renames(//,'')
      hash.must_be_instance_of Hash
      hash.empty?.must_equal true

      hash = @fch.plan_rollbacks
      hash.must_be_instance_of Hash
      hash.empty?.must_equal true

      hash = @fch.plan_reapplication('.')
      hash.must_be_instance_of Hash
      hash.empty?.must_equal true
    end

  end

  describe 'with data loaded' do
    before do
      @path = Dir.mktmpdir('test')
      @old_dir = Dir.pwd
      @fch = FolderContentsHistory.new
      Dir.chdir(@path)
      5.times do |num| 
        File.open("test-#{num}",'w') do |file|
          file.puts("a")
        end
      end
      result = @fch.load_entries('.')
    end

    it 'loads data properly' do
      result = @fch.load_entries('.')
      result.must_be_instance_of Hash
      result.keys.length.must_equal 5
    end

    it 'is changed' do
      @fch.plan_renames(/(\d)/,'\1\1')
      @fch.changed.must_be_instance_of Hash
      @fch.changed.empty?.must_equal false
    end

    it 'has no conflicts' do
      @fch.plan_renames(/(\d)/,'\1\1')
      @fch.conflicts?.must_equal false
    end

    it 'has hash as representation' do
      @fch.plan_renames(/(\d)/,'\1\1')
      @fch.to_hash.must_be_instance_of Hash
      @fch.to_hash.empty?.must_equal false
    end

    after do
      Dir.chdir(@old_dir)
      FileUtils.rm_rf(@path)
    end
  end

  describe 'when reapplying' do
    before do
      @path = Dir.mktmpdir('test')
      @old_dir = Dir.pwd
      Dir.chdir(@path)
      @fch = FolderContentsHistory.new
      File.open("test-1",'w') do |file|
        file.puts("a")
      end
      @fch.load_entries('.')
      @fch.plan_renames(/test-1/,'test-2')
      @fch.execute
      @fch.plan_renames(/test-2/,'test-3')
      @fch.execute
      File.open('test-1','w') do |file|
        file.puts
      end
    end

    it 'reapplies correctly' do
      File.delete('test-3')
      @fch.plan_reapplication('.')
      @fch.changed.must_be_instance_of Hash
      @fch.changed.empty?.must_equal false
    end

    it 'warns about conflict' do
      @fch.plan_reapplication('.')
      -> { @fch.log }.must_output(<<-MSG.gsub(/^.*\|/,'')
       |==================================================
       |!!! Some files would be lost by this operation !!!
       |==================================================
       |test-1
       |-> test-3
       MSG
       )
    end
  end
end