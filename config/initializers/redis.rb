require 'redis'

$redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
# optionally wrap with a connection pool in production:
# require 'connection_pool'
# REDIS_POOL = ConnectionPool.new(size: ENV.fetch("REDIS_POOL", 5).to_i, timeout: 5) { Redis.new(url: ENV.fetch('REDIS_URL')) }
