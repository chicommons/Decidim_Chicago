Decidim::Ai::SpamDetection.resource_analyzers = [
  {
    name: :bayes,
    strategy: Decidim::Ai::SpamDetection::Strategy::Bayes,
    options: {
      adapter: ENV.fetch("DECIDIM_SPAM_DETECTION_BACKEND_RESOURCE"),
      params: {
        url: ENV.fetch("DECIDIM_SPAM_DETECTION_BACKEND_RESOURCE_REDIS_URL")
      }
    }
  }
]
