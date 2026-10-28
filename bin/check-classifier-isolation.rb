#!/usr/bin/env ruby
# bundle exec rails runner bin/check-classifier-isolation.rb
# Uses temporary, unique namespaces and removes only those test keys.
require "securerandom"
require Rails.root.join("lib/code/namespaced_bayes")

prefix = "decidim:smoke:#{SecureRandom.hex(12)}"
url = ENV.fetch("REDIS_URL")
resource = Code::NamespacedBayesBackend.new(url: url, namespace: "#{prefix}:resource")
user = Code::NamespacedBayesBackend.new(url: url, namespace: "#{prefix}:user")
redis = Redis.new(url: url)
sentinel = "#{prefix}:unrelated"

begin
  redis.set(sentinel, "keep")
  model = ClassifierReborn::Bayes.new(:ham, :spam, backend: resource)
  model.train(:ham, "community meeting neighborhood discussion")
  model.train(:spam, "cheap pills spam promotion")
  raise "Training did not persist" unless resource.total_trainings == 2
  raise "Classifier namespaces collided" unless user.total_trainings.zero?
  result = model.classify("community neighborhood meeting")
  raise "Classification failed: #{result.inspect}" unless result.to_s.downcase == "ham"
  user.update_total_trainings(3)
  resource.reset
  raise "Reset did not clear own model" unless resource.total_trainings.zero?
  raise "Reset deleted other model" unless user.total_trainings == 3
  raise "Reset deleted unrelated key" unless redis.get(sentinel) == "keep"
  puts "PASS: Redis classifier training, classification, isolation and scoped reset"
ensure
  redis.scan_each(match: "#{prefix}:*") { |key| redis.del(key) }
end
