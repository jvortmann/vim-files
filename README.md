# A practical Vim configuration 

## Configuration
  
### Setup basic configs
  
  To set up the config, do the following (on your home directory):
  
  ```terminal
  ln -s 'path_to_where_you_cloned_the_repo' .vim/
  ln -s .vim/vimrc .vimrc
  ln -s .vim/gvimrc .gvimrc (for gui configuration)
  ```

### Setup Vundle

  We are now using Vundle to manage the plugins \o/.

  The first time you clone this repo you will also need to clone the vundle plugin (from you home folder):

  ```terminal
  git clone https://github.com/gmarik/vundle.git .vim/bundle/vundle
  ```

  Then you need to tell vundle to install the plugins:
  ```terminal
  vim +BundleInstall +qall
  ```
  or from inside Vim:

  ```vim
  :BundleInstall
  ```

### Extras
  If you want to use the fancy status bar on the Mac (it is on by default on the Mac) you will also need to install the Menlo-Powerline font on the extra/ folder.
  Font from: https://gist.github.com/1595572

## Shortcuts (fairly outdated list, I will update them soon)

  The majority of shortcuts are made to use with Rails development. So far this is done by default, but the intent of this config if to be flexible and so there will be a way to define which shortcuts to create depending on what is being used.

  * AutoComplete

    ``
    <Control-Shift-Space>       : opens the autocomplete menu
    ``

  * NerdTree

    ``
    <F2>                        : open the NERDTree windows (drawer)
    ``

  * Search/Open **OUDATED**
   
   ``
    <Alt/Option-Shift-f>        : search for a file (it is possible to filter the search)
    ``
    ``
    <Alt/Option-Shift-o>        : show the open files (buffers). The last viewed file is selected and you can also filter the result
    ``
    ``
    <Alt/Option-Shift-t> c      : search for a tag in the current buffer
    ``
    ``
    <Alt/Option-Shift-t> a      : search for a tag in all open buffers
    ``
    ``
    <Alt/Option-Shift-t> w      : search for the word under the cursor as a tag in current buffer
    ``
    ``
    <Alt/Option-Shift-t> W      : search for the word under the cursor as a tag in all open buffers
    ``
    ``
    <Alt/Option-Shift-t> s      : search for the selection as a tag in current buffer
    ``
    ``
    <Alt/Option-Shift-t> S      : search for the selection as a tag in all open buffers
    ``

  * Rails specific (you can press tab to auto-complete in most of them) **OUTDATED**
    
    ``
    <Alt/Option-Shift-m>        : opens a model 
    ``
    ``
    <Alt/Option-Shift-c>        : opens a controller
    ``
    ``
    <Alt/Option-Shift-v>        : opens a view
    ``
    ``
    <Alt/Option-Shift-s>        : runs a script
    ``
    ``
    <Alt/Option-Shift-e>        : extract a partial
    ``
    ``
    <Alt/Option-Shift-g>        : runs generate
    ``
    ``
    <Alt/Option-Shift-l>        : opens the log
    ``
    ``
    <Alt/Option-Shift-p>        : preview the file
    ``
    ``
    <Alt/Option-Shift-t> t      : create tags file for the current project (works only for rails projects)
    ``
    ``
    <F3>                        : goes to the test file (test unit/rspec)
    ``
    ``
    <F4>                        : goes to the migration file (models) or view file (controller method)
    ``
    ``
    <F5>                        : runs the test file
    ``
    ``
    <F6>                        : runs the test under the cursor
    ``

  * Git specific

    ``
    <F7>                        : blame
    ``
    ``
    <Shift-F7>                  : diff
    ``

  * Navigation

    ``
    <Control-Tab>               : goes to the next tab
    ``
    ``
    <Control-Shift-Tab>         : goes to the previous tab
    ``
    ``
    <Control-Down>              : scrolls down
    ``
    ``
    <Control-Up>                : scrolls up
    ``

  * Windows

    ``
    <Space><Space>              : expand the current window
    ``
    ``
    <Space>=                    : set the window back to the default size
    ``
    ``
    <Space>o                    : keep only the current window open
    ``
    ``
    <Space>_                    : expand current horizontal split
    ``
    ``
    <Space>|                    : expand current vertical split
    ``
    ``
    <Control-h>                 : goes to the splitted window at the left
    ``
    ``
    <Control-j>                 : goes to the splitted window at the down
    ``
    ``
    <Control-k>                 : goes to the splitted window at the up
    ``
    ``
    <Control-l>                 : goes to the splitted window at the right
    ``
    ``
    -                           : decrease the font size
    ``
    ``
    +                           : increase the font size
    ``

  * Dealing with lines

    ``
    <Alt/Option-Shift-Up>       : move the selected text or line up
    ``
    ``
    <Alt/Option-Shift-Down>     : move the selected text or line down
    ``
    ``
    <Alt/Option-Shift-d>        : duplicate the line under the cursor
    ``
    ``
    <Alt/Option-/>              : comment the line
    ``

  * Other

    ``
    <Alt/Option-a>              : select all
    ``

  * TagBar

    ``
    <Alt/Option-i>              : open the tagbar and focus it
    ``
    ``
    <Alt/Option-Shift-i>        : toggle the tagbar
    ``

  * gundo

    ``
    <Alt/Option-Shift-u>        : toggle gundo and focus it
    ``

  * Tasks

    ``
    <Alt/Option-Shift-Enter>    : toggle task (done/undone)
    ``
