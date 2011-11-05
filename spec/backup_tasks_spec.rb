require 'fakefs/safe'
require 'fakefs/spec_helpers'
require 'rake'
require 'rspec'

load File.expand_path(File.join(File.dirname(__FILE__), "..", "Rakefile"))

describe "Rake task" do
  include FakeFS::SpecHelpers

  before :each do
    ENV['HOME'] = "/home/john"
    FileUtils.mkdir_p "/home/john"
  end

  def reenable_prerequisites(task)
    Rake::Task[task].prerequisite_tasks.each do |prerequisite|
      prerequisite.reenable
    end
  end
  private :reenable_prerequisites

  context "for backing up" do
    context "the vim folder" do
      before :each do
        reenable_prerequisites "backup:vim_folder"
      end

      after :each do
        Rake::Task['backup:vim_folder'].reenable
      end

      it "should copy to .vim.backup" do
        FileUtils.mkdir_p File.expand_path("~/.vim")
        Rake::Task['backup:vim_folder'].invoke
        File.should exist File.expand_path("~/.vim.backup")
      end

      it "should not copy if it doesn't exist" do
        Rake::Task["backup:vim_folder"].invoke
        File.should_not exist File.expand_path("~/.vim.backup")
      end
    end

    context "the vimrc file" do
      before :each do
        reenable_prerequisites "backup:vimrc"
      end

      after :each do
        Rake::Task['backup:vimrc'].reenable
      end

      it "should copy to .vimrc.backup" do
        FileUtils.touch File.expand_path("~/.vimrc")
        Rake::Task['backup:vimrc'].invoke
        File.should exist File.expand_path("~/.vimrc.backup")
      end

      it "should not copy if it doesn't exist" do
        Rake::Task["backup:vimrc"].invoke
        File.should_not exist File.expand_path("~/.vimrc.backup")
      end
    end

    context "the gvimrc file" do
      before :each do
        reenable_prerequisites "backup:gvimrc"
      end

      after :each do
        Rake::Task['backup:gvimrc'].reenable
      end

      it "should copy to .gvimrc.backup" do
        FileUtils.touch File.expand_path("~/.gvimrc")
        Rake::Task['backup:gvimrc'].invoke
        File.should exist File.expand_path("~/.gvimrc.backup")
      end

      it "should not copy if it doesn't exist" do
        Rake::Task["backup:gvimrc"].invoke
        File.should_not exist File.expand_path("~/.gvimrc.backup")
      end
    end
  end

  context "backing up everything" do

    before :each do
      Rake::Task["backup:all"].prerequisite_tasks.each do |prerequisite|
        prerequisite.reenable
      end
    end

    after :each do
      Rake::Task["backup:all"].reenable
    end

    it "should copy all the configs at once" do
      FileUtils.mkdir_p File.expand_path("~/.vim")
      FileUtils.touch File.expand_path("~/.vimrc")
      FileUtils.touch File.expand_path("~/.gvimrc")

      Rake::Task["backup:all"].invoke

      File.should exist File.expand_path("~/.vim.backup")
      File.should exist File.expand_path("~/.vimrc.backup")
      File.should exist File.expand_path("~/.gvimrc.backup")
    end

  end

end
