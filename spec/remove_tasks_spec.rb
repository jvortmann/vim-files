require 'fakefs/safe'
require 'fakefs/spec_helpers'
require 'rake'
require 'rspec'
require 'spec_helper'

describe "Rake task" do
  include FakeFS::SpecHelpers
  include Rake::SpecHelpers

  context "for removing" do
    context "the vim folder" do
      before :each do
        reenable_prerequisites "remove:vim_folder"
      end

      after :each do
        Rake::Task['remove:vim_folder'].reenable
      end

      it "should do it" do
        FileUtils.mkdir_p File.expand_path("~/.vim")
        Rake::Task['remove:vim_folder'].invoke
        File.should_not exist File.expand_path("~/.vim")
      end

    end
 
    context "the vimrc file" do
      before :each do
        reenable_prerequisites "remove:vimrc"
      end

      after :each do
        Rake::Task['remove:vimrc'].reenable
      end

      it "should do it" do
        FileUtils.touch File.expand_path("~/.vimrc")
        Rake::Task['remove:vimrc'].invoke
        File.should_not exist File.expand_path("~/.vimrc")
      end
    end

    context "the gvimrc file" do
      before :each do
        reenable_prerequisites "remove:gvimrc"
      end

      after :each do
        Rake::Task['remove:gvimrc'].reenable
      end

      it "should do it" do
        FileUtils.touch File.expand_path("~/.gvimrc")
        Rake::Task['remove:gvimrc'].invoke
        File.should_not exist File.expand_path("~/.gvimrc")
      end
    end

  end

  context "removing all local setup" do

    before :each do
      Rake::Task["remove:all"].prerequisite_tasks.each do |prerequisite|
        prerequisite.reenable
      end
    end

    after :each do
      Rake::Task["remove:all"].reenable
    end

    it "do it at once" do
      FileUtils.mkdir_p File.expand_path("~/.vim")
      FileUtils.touch File.expand_path("~/.vimrc")
      FileUtils.touch File.expand_path("~/.gvimrc")

      Rake::Task["remove:all"].invoke

      File.should_not exist File.expand_path("~/.vim")
      File.should_not exist File.expand_path("~/.vimrc")
      File.should_not exist File.expand_path("~/.gvimrc")
    end

  end

end
