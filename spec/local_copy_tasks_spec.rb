require 'fakefs/safe'
require 'fakefs/spec_helpers'
require 'rake'
require 'rspec'
require 'spec_helper'

describe "Rake task" do
  include FakeFS::SpecHelpers
  include Rake::SpecHelpers

  context "for copying" do
    context "the vimrc local setup" do
      before :each do
        reenable_prerequisites "local:vimrc"
      end

      after :each do
        Rake::Task['local:vimrc'].reenable
      end

      it "should copy to .vimrc.local" do
        FileUtils.touch File.expand_path("~/.vimrc")
        Rake::Task['local:vimrc'].invoke
        File.should exist File.expand_path("~/.vimrc.local")
      end

      it "should not copy if it doesn't exist" do
        Rake::Task["local:vimrc"].invoke
        File.should_not exist File.expand_path("~/.vimrc.local")
      end
    end

    context "the gvimrc local setup" do
      before :each do
        reenable_prerequisites "local:gvimrc"
      end

      after :each do
        Rake::Task['local:gvimrc'].reenable
      end

      it "should copy to .gvimrc.local" do
        FileUtils.touch File.expand_path("~/.gvimrc")
        Rake::Task['local:gvimrc'].invoke
        File.should exist File.expand_path("~/.gvimrc.local")
      end

      it "should not copy if it doesn't exist" do
        Rake::Task["local:gvimrc"].invoke
        File.should_not exist File.expand_path("~/.gvimrc.local")
      end
    end
  end

  context "copying all local setup" do

    before :each do
      Rake::Task["local:all"].prerequisite_tasks.each do |prerequisite|
        prerequisite.reenable
      end
    end

    after :each do
      Rake::Task["local:all"].reenable
    end

    it "should copy all the configs at once" do
      FileUtils.touch File.expand_path("~/.vimrc")
      FileUtils.touch File.expand_path("~/.gvimrc")

      Rake::Task["local:all"].invoke

      File.should exist File.expand_path("~/.vimrc.local")
      File.should exist File.expand_path("~/.gvimrc.local")
    end

  end

end
