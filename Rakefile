desc "Backups current files to .backup"
task :backup do
  #cp_r File.expand_path("~/.vim"), File.expand_path("~/.vim.old"), :verbose => true
  FileUtils.cp ".vimrc", ".vimrc.backup"
  #cp File.expand_path("~/.gvimrc"), File.expand_path("~/.gvimrc.old"), :verbose => true
end

desc "Make local copy of configs"
task :local do
  cp File.expand_path("~/.vimrc"), File.expand_path("~/.vimrc.local"), :verbose => true
  cp File.expand_path("~/.gvimrc"), File.expand_path("~/.gvimrc.local"), :verbose => true
end
