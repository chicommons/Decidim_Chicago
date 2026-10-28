# frozen_string_literal: true

# This migration comes from decidim_conferences (originally 20210310134942)
class AddFollowableCounterCacheToConferences < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_conferences, :follows_count, :integer, null: false, default: 0, index: true

    reversible do |dir|
      dir.up do
        # Historical migrations must work even when the Conferences engine is
        # disabled. Preserve the backfill without loading its current model.
        execute <<~SQL
          UPDATE decidim_conferences AS conferences
          SET follows_count = (
            SELECT COUNT(*) FROM decidim_follows AS follows
            WHERE follows.decidim_followable_type = 'Decidim::Conference'
              AND follows.decidim_followable_id = conferences.id
          )
        SQL
      end
    end
  end
end
