require 'fakefs/safe'
require 'fakefs/spec_helpers'
require 'rake'
require 'rspec'
require 'spec_helper'

describe "Rake task" do
  include FakeFS::SpecHelpers
  include Rake::SpecHelpers


  context "for installing" do
    context "the vim folder" do
      context "using copies" do
        before :each do
          reenable_prerequisites "install:vim_folder:copy"
        end

        after :each do
          Rake::Task['install:vim_folder:copy'].reenable
        end

        it "should backup and then copy if present" do
          FileUtils.mkdir_p File.expand_path("~/.vim")

          Rake::Task['install:vim_folder:copy'].invoke
          File.should exist File.expand_path("~/.vim.backup")
          File.should exist File.expand_path("~/.vim")
        end

        #it "should overwrite with backup if present" do
        #FileUtils.mkdir_p File.expand_path("~/.vim.backup")
        #FileUtils.mkdir_p File.expand_path("~/.vim")
        #Rake::Task['install:vim_folder'].invoke
        #File.should exist File.expand_path("~/.vim")
        #end

        #it "should not copy backup if it doesn't exist" do
        #Rake::Task["install:vim_folder"].invoke
        #File.should_not exist File.expand_path("~/.vim")
        #end
      end
      context "using links" do
        before :each do
          reenable_prerequisites "install:vim_folder:link"
        end

        after :each do
          Rake::Task['install:vim_folder:link'].reenable
        end

        it "should backup, remove and then link if present" do
          FileUtils.mkdir_p File.expand_path("~/.vim")

          Rake::Task['install:vim_folder:link'].invoke
          File.should exist File.expand_path("~/.vim.backup")
          File.should exist File.expand_path("~/.vim")
        end

        #it "should overwrite with backup if present" do
        #FileUtils.mkdir_p File.expand_path("~/.vim.backup")
        #FileUtils.mkdir_p File.expand_path("~/.vim")
        #Rake::Task['install:vim_folder'].invoke
        #File.should exist File.expand_path("~/.vim")
        #end

        #it "should not copy backup if it doesn't exist" do
        #Rake::Task["install:vim_folder"].invoke
        #File.should_not exist File.expand_path("~/.vim")
        #end
      end
    end
  end

  #context "the vimrc file" do
  #before :each do
  #reenable_prerequisites "install:vimrc"
  #end

  #after :each do
  #Rake::Task['install:vimrc'].reenable
  #end

  #it "should create from backup" do
  #FileUtils.touch File.expand_path("~/.vimrc.backup")
  #Rake::Task['install:vimrc'].invoke
  #File.should exist File.expand_path("~/.vimrc")
  #end

  #it "should overwrite with backup if present" do
  #FileUtils.touch File.expand_path("~/.vimrc.backup")
  #FileUtils.touch File.expand_path("~/.vimrc")
  #Rake::Task['install:vimrc'].invoke
  #File.should exist File.expand_path("~/.vimrc")
  #end

  #it "should not copy backup if it doesn't exist" do
  #Rake::Task["install:vimrc"].invoke
  #File.should_not exist File.expand_path("~/.vimrc")
  #end
  #end

  #context "the gvimrc file" do
  #before :each do
  #reenable_prerequisites "install:gvimrc"
  #end

  #after :each do
  #Rake::Task['install:gvimrc'].reenable
  #end

  #it "should create from backup" do
  #FileUtils.touch File.expand_path("~/.gvimrc.backup")
  #Rake::Task['install:gvimrc'].invoke
  #File.should exist File.expand_path("~/.gvimrc")
  #end

  #it "should overwrite with backup if present" do
  #FileUtils.touch File.expand_path("~/.gvimrc.backup")
  #FileUtils.touch File.expand_path("~/.gvimrc")
  #Rake::Task['install:gvimrc'].invoke
  #File.should exist File.expand_path("~/.gvimrc")
  #end

  #it "should not copy backup if it doesn't exist" do
  #Rake::Task["install:gvimrc"].invoke
  #File.should_not exist File.expand_path("~/.gvimrc")
  #end
  #end
  #end

  #context "install all configs" do

  #before :each do
  #Rake::Task["install:all"].prerequisite_tasks.each do |prerequisite|
  #prerequisite.reenable
  #end
  #end

  #after :each do
  #Rake::Task["install:all"].reenable
  #end

  #it "should install all the configs at once" do
  #FileUtils.mkdir_p File.expand_path("~/.vim.backup")
  #FileUtils.touch File.expand_path("~/.vimrc.backup")
  #FileUtils.touch File.expand_path("~/.gvimrc.backup")

  #Rake::Task["install:all"].invoke

  #File.should exist File.expand_path("~/.vim")
  #File.should exist File.expand_path("~/.vimrc")
  #File.should exist File.expand_path("~/.gvimrc")
  #end

  #it "should overwrite all the configs if present" do
  #FileUtils.mkdir_p File.expand_path("~/.vim.backup")
  #FileUtils.touch File.expand_path("~/.vimrc.backup")
  #FileUtils.touch File.expand_path("~/.gvimrc.backup")
  #FileUtils.mkdir_p File.expand_path("~/.vim")
  #FileUtils.touch File.expand_path("~/.vimrc")
  #FileUtils.touch File.expand_path("~/.gvimrc")

  #Rake::Task["install:all"].invoke

  #File.should exist File.expand_path("~/.vim")
  #File.should exist File.expand_path("~/.vimrc")
  #File.should exist File.expand_path("~/.gvimrc")
  #end

  #end

end
