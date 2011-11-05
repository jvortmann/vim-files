desc "Backup all config"
task :backup => 'backup:all'

desc "Copy local all config"
task :local => 'local:all'

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

namespace :local do
  desc "Keep local vimrc setup"
  task :vimrc do
    FileUtils.cp File.expand_path("~/.vimrc"), File.expand_path("~/.vimrc.local") if File.exist? File.expand_path("~/.vimrc")
  end

  desc "Keep local gvimrc setup"
  task :gvimrc do
    FileUtils.cp File.expand_path("~/.gvimrc"), File.expand_path("~/.gvimrc.local") if File.exist? File.expand_path("~/.gvimrc")
  end

  task :all => [:vimrc, :gvimrc]
end
