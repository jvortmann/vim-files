require 'fakefs/safe'
require 'fakefs/spec_helpers'
require 'rake'
require 'rspec'
require 'spec_helper'

describe "Rake task" do
  include FakeFS::SpecHelpers
  include Rake::SpecHelpers

  context "for restoring" do
    context "the vim folder" do
      before :each do
        reenable_prerequisites "restore:vim_folder"
      end

      after :each do
        Rake::Task['restore:vim_folder'].reenable
      end

      it "should create from backup" do
        FileUtils.mkdir_p File.expand_path("~/.vim.backup")
        Rake::Task['restore:vim_folder'].invoke
        File.should exist File.expand_path("~/.vim")
      end

      it "should overwrite with backup if present" do
        FileUtils.mkdir_p File.expand_path("~/.vim.backup")
        FileUtils.mkdir_p File.expand_path("~/.vim")
        Rake::Task['restore:vim_folder'].invoke
        File.should exist File.expand_path("~/.vim")
      end

      it "should not copy backup if it doesn't exist" do
        Rake::Task["restore:vim_folder"].invoke
        File.should_not exist File.expand_path("~/.vim")
      end
    end

    context "the vimrc file" do
      before :each do
        reenable_prerequisites "restore:vimrc"
      end

      after :each do
        Rake::Task['restore:vimrc'].reenable
      end

      it "should create from backup" do
        FileUtils.touch File.expand_path("~/.vimrc.backup")
        Rake::Task['restore:vimrc'].invoke
        File.should exist File.expand_path("~/.vimrc")
      end

      it "should overwrite with backup if present" do
        FileUtils.touch File.expand_path("~/.vimrc.backup")
        FileUtils.touch File.expand_path("~/.vimrc")
        Rake::Task['restore:vimrc'].invoke
        File.should exist File.expand_path("~/.vimrc")
      end

      it "should not copy backup if it doesn't exist" do
        Rake::Task["restore:vimrc"].invoke
        File.should_not exist File.expand_path("~/.vimrc")
      end
    end

    context "the gvimrc file" do
      before :each do
        reenable_prerequisites "restore:gvimrc"
      end

      after :each do
        Rake::Task['restore:gvimrc'].reenable
      end

      it "should create from backup" do
        FileUtils.touch File.expand_path("~/.gvimrc.backup")
        Rake::Task['restore:gvimrc'].invoke
        File.should exist File.expand_path("~/.gvimrc")
      end

      it "should overwrite with backup if present" do
        FileUtils.touch File.expand_path("~/.gvimrc.backup")
        FileUtils.touch File.expand_path("~/.gvimrc")
        Rake::Task['restore:gvimrc'].invoke
        File.should exist File.expand_path("~/.gvimrc")
      end

      it "should not copy backup if it doesn't exist" do
        Rake::Task["restore:gvimrc"].invoke
        File.should_not exist File.expand_path("~/.gvimrc")
      end
    end
  end

  context "restore all configs" do

    before :each do
      Rake::Task["restore:all"].prerequisite_tasks.each do |prerequisite|
        prerequisite.reenable
      end
    end

    after :each do
      Rake::Task["restore:all"].reenable
    end

    it "should restore all the configs at once" do
      FileUtils.mkdir_p File.expand_path("~/.vim.backup")
      FileUtils.touch File.expand_path("~/.vimrc.backup")
      FileUtils.touch File.expand_path("~/.gvimrc.backup")

      Rake::Task["restore:all"].invoke

      File.should exist File.expand_path("~/.vim")
      File.should exist File.expand_path("~/.vimrc")
      File.should exist File.expand_path("~/.gvimrc")
    end

    it "should overwrite all the configs if present" do
      FileUtils.mkdir_p File.expand_path("~/.vim.backup")
      FileUtils.touch File.expand_path("~/.vimrc.backup")
      FileUtils.touch File.expand_path("~/.gvimrc.backup")
      FileUtils.mkdir_p File.expand_path("~/.vim")
      FileUtils.touch File.expand_path("~/.vimrc")
      FileUtils.touch File.expand_path("~/.gvimrc")

      Rake::Task["restore:all"].invoke

      File.should exist File.expand_path("~/.vim")
      File.should exist File.expand_path("~/.vimrc")
      File.should exist File.expand_path("~/.gvimrc")
    end

  end

end
