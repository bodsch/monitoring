
require_relative 'version'
require_relative 'annotations'
require_relative 'tools'
require_relative 'information'
require_relative 'host'

module Monitoring

  class Client

    include Logging

    include Monitoring::Annotations
    include Monitoring::Tools
    include Monitoring::Information
    include Monitoring::Host

    def initialize( settings )

      raise ArgumentError.new(format('wrong type. \'settings\' must be an Hash, given \'%s\'', settings.class.to_s)) unless( settings.is_a?(Hash) )
      raise ArgumentError.new('missing settings') if( settings.size.zero? )

      mq_host        = settings.dig(:mq, :host)
      mq_port        = settings.dig(:mq, :port)
      mq_queue       = settings.dig(:mq, :queue)     || 'mq-rest-service'
      redis_host     = settings.dig(:redis, :host)
      redis_port     = settings.dig(:redis, :port)
      mysql_host     = settings.dig(:mysql, :host)
      mysql_schema   = settings.dig(:mysql, :schema)
      mysql_user     = settings.dig(:mysql, :user)
      mysql_password = settings.dig(:mysql, :password)
      consul_host    = settings.dig(:consul, :host)
      consul_port    = settings.dig(:consul, :port) || 8500

      mq_settings     = { beanstalk: { host: mq_host, port: mq_port, queue: mq_queue } }
      mysql_settings  = { mysql: { host: mysql_host, user: mysql_user, password: mysql_password, schema: mysql_schema } }
      redis_settings  = { redis: { host: redis_host } }
      consul_settings = { consul: { host: consul_host, port: consul_port } }

      version              = Monitoring::VERSION
      date                 = Monitoring::DATE

      logger.info( '-----------------------------------------------------------------' )
      logger.info( ' CoreMedia - Monitoring Service' )
      logger.info( "  Version #{version} (#{date})" )
      logger.info( '  Copyright 2016-2018 CoreMedia' )
      logger.info( '  used Services:' )
      logger.info( "    - mysql        : #{mysql_host}@#{mysql_schema}" )
      logger.info( "    - redis        : #{redis_host}:#{redis_port}" )
      logger.info( "    - message queue: #{mq_host}:#{mq_port}/#{mq_queue}" )
      logger.info( "    - consul       : #{consul_host}:#{consul_port}" )
      logger.info( '-----------------------------------------------------------------' )
      logger.info( '' )

      @redis       = Storage::RedisClient.new( redis_settings )
      @mq_consumer = MessageQueue::Consumer.new( mq_settings )
      @mq_producer = MessageQueue::Producer.new( mq_settings )
      @database    = Storage::MySQL.new( mysql_settings )

      consul      = Diplomat.configure do |config|
        # Set up a custom Consul URL
        config.url = "http://#{consul_host}:#{consul_port}"
        # Set up a custom Faraday Middleware
        #config.middleware = MyCustomMiddleware
        # Connect into consul with custom access token (ACL)
        #config.acl_token =  "xxxxxxxx-yyyy-zzzz-1111-222222222222"
        # Set extra Faraday configuration options
        #config.options = {ssl: { version: :TLSv1_2 }}
      end

      logger.debug( "consul: #{consul.inspect}" )
      logger.debug( "consul: #{Diplomat::Status.leader()}")
    end


  end

end
