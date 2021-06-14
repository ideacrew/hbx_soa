case Padrino.env
 when :production then Ohm.redis = Redic.new("redis://" + ENV['REDIS_HOST_SOA'] + ":6379")
end
