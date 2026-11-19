return {
  { -- projectionist
    'tpope/vim-projectionist',
    init = function()
      local transformations = vim.g.projectionist_transformations or {}
      transformations.nontest = function(input)
        if input:match('%.test$') or input:match('%.spec$') then
          return '\24'
        end
        return input
      end
      vim.g.projectionist_transformations = transformations

      -- The key order of a Vim dict depends on the order of insertion, and projectionist
      -- reads the heuristics in that order. A Lua table has no order, so each dict is a
      -- list of {key, value} pairs, and set_dict adds the keys in that order.
      local function dict(...)
        return { entries = { ... } }
      end

      local function projection(alternate, type)
        return dict({ 'alternate', alternate }, { 'type', type })
      end

      local function set_dict(target, entries)
        vim.cmd(('let %s = {}'):format(target))
        for _, entry in ipairs(entries) do
          local key, value = entry[1], entry[2]
          local item = ('%s[%s]'):format(target, vim.fn.string(key))
          if type(value) == 'table' and value.entries then
            set_dict(item, value.entries)
          else
            vim.cmd(('let %s = %s'):format(item, vim.fn.string(value)))
          end
        end
      end

      local shared_markers = '.tool-versions|mise.toml|package.json'

      local shared_projections = dict(
        { '*.go', projection({ '{}_test.go' }, 'src') },
        { 'src/*.go', projection({ 'test/{}_test.go' }, 'src') },
        { 'lib/*.go', projection({ 'test/{}_test.go' }, 'lib') },
        { '*_test.go', projection({ '{}.go' }, 'spec') },
        { 'test/*_test.go', projection({ 'src/{}.go', 'lib/{}.go' }, 'spec') }
      )

      local heuristics = dict(
        { 'bin/spring', dict(
          { 'spec/*_spec.rb', dict({ 'runner', 'bin/spring rspec' }) }
        ) },
        { '!bin/spring&Gemfile', dict(
          { 'spec/*_spec.rb', dict({ 'runner', 'bundle exec rspec' }) }
        ) },
        { 'config/application.rb', dict(
          { 'app/*.rb', projection({ 'spec/{}_spec.rb', 'test/{}_test.rb' }, 'app') },
          { 'app/controllers/api/*_controller.rb', projection(
            { 'spec/requests/api/{}_spec.rb', 'spec/requests/api/{}_controller_spec.rb', 'test/{}_test.rb' },
            'app'
          ) },
          { 'spec/*_spec.rb', projection('app/{}.rb', 'spec') },
          { 'test/*_test.rb', projection('app/{}.rb', 'spec') },
          { 'lib/*.rb', projection({ 'spec/lib/{}_spec.rb', 'test/lib/{}_test.rb' }, 'lib') },
          { 'spec/lib/*_spec.rb', projection('lib/{}.rb', 'spec') },
          { 'spec/requests/*_spec.rb', projection({ 'app/controllers/{}.rb', 'app/controllers/{}_controller.rb' }, 'spec') },
          { 'test/lib/*_test.rb', projection('lib/{}.rb', 'spec') },
          { 'lib/jobs/*.rb', projection('test/jobs/{}_test.rb', 'lib') },
          { 'test/jobs/*_test.rb', projection('lib/jobs/{}.rb', 'spec') }
        ) },
        { 'Gemfile', dict(
          { 'Gemfile', projection('Gemfile.lock', 'source') },
          { 'Gemfile.lock', projection('Gemfile', 'source') },
          { 'spec/*_spec.rb', projection('lib/{}.rb', 'spec') }
        ) },
        { '*.gemspec|.ruby-version|.tool-versions', dict(
          { 'lib/*.rb', projection('spec/{}_spec.rb', 'lib') },
          { 'spec/*_spec.rb', projection('lib/{}.rb', 'spec') }
        ) },
        { 'mix.exs|mix.lock|.tool-versions', dict(
          { 'lib/*.ex', projection({ 'test/{}_test.ex', 'test/{}_test.exs' }, 'lib') },
          { 'test/*_test.exs', projection({ 'lib/{}.ex', 'lib/{}.exs' }, 'spec') }
        ) },
        { shared_markers, shared_projections }
      )

      local function add_test_alternates(projections, ext)
        local mirrored = {}
        for _, folder in ipairs({ 'tests', 'test', 'spec', 'specs' }) do
          for _, suffix in ipairs({ 'test', 'spec' }) do
            table.insert(mirrored, folder .. '/{nontest}.' .. suffix .. '.' .. ext)
            table.insert(projections, {
              folder .. '/*.' .. suffix .. '.' .. ext,
              projection({ 'src/{}.' .. ext, '{}.' .. ext }, 'spec'),
            })
          end
        end
        for _, suffix in ipairs({ 'test', 'spec' }) do
          table.insert(projections, { '*.' .. suffix .. '.' .. ext, projection({ '{}.' .. ext }, 'spec') })
        end
        table.insert(projections, { 'src/*.' .. ext, projection(mirrored, 'src') })
        table.insert(projections, {
          '*.' .. ext,
          projection(vim.list_extend({ '{nontest}.test.' .. ext, '{nontest}.spec.' .. ext }, mirrored), 'src'),
        })
      end

      for _, ext in ipairs({ 'ts', 'tsx', 'js', 'jsx' }) do
        add_test_alternates(shared_projections.entries, ext)
      end

      set_dict('g:projectionist_heuristics', heuristics.entries)
    end,
  },
}
