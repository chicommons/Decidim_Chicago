FROM decidim/decidim:0.31.4

# The upstream image contains a generated example app. Build THIS repository,
# rather than accidentally deploying that app (Compose's bind mount hid this).
# Keep it in a separate directory so inherited example migrations cannot leak
# into the application's migration path, including through cached image layers.
WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends libicu-dev libyaml-dev libpq-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' \
    && bundle config set --local frozen true \
    && bundle install

COPY package.json package-lock.json ./
RUN npm ci --include=dev

COPY . .
ENV RAILS_ENV=production \
    NODE_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

# Asset builds must not require production credentials or connect to services.
# This value is scoped to this RUN only, not persisted in the runtime image.
RUN SECRET_KEY_BASE_DUMMY=1 SECRET_KEY_BASE=asset-build-only \
    DECIDIM_SPAM_DETECTION_BACKEND_RESOURCE=memory \
    DECIDIM_SPAM_DETECTION_BACKEND_USER=memory \
    bundle exec rails runner 'puts "Validated #{ActiveRecord::Base.connection_pool.migration_context.migrations.size} application migrations in #{Rails.root}"' \
    && SECRET_KEY_BASE_DUMMY=1 SECRET_KEY_BASE=asset-build-only \
    DECIDIM_SPAM_DETECTION_BACKEND_RESOURCE=memory \
    DECIDIM_SPAM_DETECTION_BACKEND_USER=memory \
    bundle exec rails assets:precompile \
    && rm -rf tmp/cache

ENTRYPOINT []
CMD ["sh", "-c", "exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
