require 'fakefs/safe'
require 'fakefs/spec_helpers'
require 'rake'
require 'rspec'

load File.expand_path(File.join(File.dirname(__FILE__), "..", "Rakefile"))

describe "Rake tasks" do
  include FakeFS::SpecHelpers

  before do
    FileUtils.touch ".vimrc"
  end

  context "for backing up configs" do
    it "should copy .vimrc to .vimrc.backup" do
      Rake::Task[:backup].invoke
      File.should exist ".vimrc.backup"
    end
  end
end
