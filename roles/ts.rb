name 'ts'
description 'A server with ts installed'
run_list(
  'recipe[git]',
  'recipe[ts]'
)