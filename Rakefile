desc "Backup all configs"
task :backup => 'backup:all'

namespace :backup do
  desc "Backup vim folder"
  task :vim_folder do
    FileUtils.cp_r File.expand_path("~/.vim"), File.expand_path("~/.vim.backup") if File.exist? File.expand_path("~/.vim")
  end

  desc "Backup vimrc"
  task :vimrc do
    FileUtils.cp File.expand_path("~/.vimrc"), File.expand_path("~/.vimrc.backup") if File.exist? File.expand_path("~/.vimrc")
  end

  desc "Backup gvimrc"
  task :gvimrc do
    FileUtils.cp File.expand_path("~/.gvimrc"), File.expand_path("~/.gvimrc.backup") if File.exist? File.expand_path("~/.gvimrc")
  end

  task :all => [:vim_folder, :vimrc, :gvimrc]
end

desc "Make local copy of configs"
task :local do
  cp File.expand_path("~/.vimrc"), File.expand_path("~/.vimrc.local"), :verbose => true
  cp File.expand_path("~/.gvimrc"), File.expand_path("~/.gvimrc.local"), :verbose => true
end
