require "redis"
require "classifier-reborn"

module Code
  # ClassifierReborn's backend uses bare keys and FLUSHDB on reset. Upstash
  # only offers database 0, so isolate resource/user models by key prefix.
  class ClassifierRedis
    KEY_COMMANDS = %i[setnx set get incrby hget hincrby sadd smembers hdel hexists].freeze

    def initialize(options)
      options = options.dup
      @prefix = "#{options.delete(:namespace)}:"
      @redis = Redis.new(options)
    end

    KEY_COMMANDS.each do |command|
      define_method(command) do |key, *arguments|
        @redis.public_send(command, "#{@prefix}#{key}", *arguments)
      end
    end

    # Match ClassifierReborn's reset API without deleting another classifier's
    # model or unrelated Redis keys. Training/reset should not run concurrently.
    def flushdb
      @redis.scan_each(match: "#{@prefix}*") do |key|
        @redis.del(key)
      end
    end
  end

  class NamespacedBayesBackend < ClassifierReborn::BayesRedisBackend
    def initialize(options)
      @redis = ClassifierRedis.new(options)
      @redis.setnx(:total_words, 0)
      @redis.setnx(:total_trainings, 0)
    end
  end

  class NamespacedBayes < Decidim::Ai::SpamDetection::Strategy::Bayes
    private

    def configured_backend
      # Memory is used only for the credential-free asset build (RUN-scoped).
      return super if options[:adapter].to_s == "memory"

      NamespacedBayesBackend.new(options[:params])
    end
  end
end