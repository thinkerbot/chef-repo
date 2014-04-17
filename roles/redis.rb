name 'redis'
description 'A redis master on slave (on a single machine)'
default_attributes({
  'redisio' => {
    'servers' => [
      { 'port' => '6379' },
      { 'port' => '6380', 'slaveof' => { 'address' => '127.0.0.1', 'port' => '6379' }  }
    ]
  }
})
run_list(
  'recipe[redisio::install]',
  'recipe[redisio::enable]'
)
