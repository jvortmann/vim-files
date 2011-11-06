require 'rake'

load File.expand_path(File.join(File.dirname(__FILE__), "..", "Rakefile"))

module Rake
  module SpecHelpers
    def self.extended(example_group)
      example_group.use_rake_spec_helper(example_group)
    end

    def self.included(example_group)
      example_group.extend self
    end

    def use_rake_spec_helper(describe_block)
      describe_block.before :each do
        ENV['HOME'] = "/home/john"
        FileUtils.mkdir_p "/home/john"

        ENV['REPO_PWD'] = File.expand_path("~/vim_repo")
        FileUtils.mkdir_p File.expand_path("~/vim_repo")
      end
   end

    def reenable_prerequisites(task)
      Rake::Task[task].prerequisite_tasks.each do |prerequisite|
        prerequisite.reenable
      end
    end
  end
end
