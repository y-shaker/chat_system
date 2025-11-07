Rails.application.config.after_initialize do
  # Only run when Rails is serving requests (not in migrations, rake, etc.)
  next unless defined?(Rails::Server) || defined?(Rails::Console)

  Thread.new do
    sleep 2 # wait for Elasticsearch container to start

    begin
      es_url = ENV.fetch('ELASTICSEARCH_URL', 'http://elasticsearch:9200')
      client = Elasticsearch::Client.new(
        url: es_url,
        retry_on_failure: true,
        transport_options: { request: { timeout: 5 } }
      )

      Elasticsearch::Model.client = client

      if client.ping
        Rails.logger.info("[Elasticsearch Setup] Connected to Elasticsearch at #{es_url}")

        index_name = Message.index_name
        unless client.indices.exists?(index: index_name)
          Rails.logger.info("[Elasticsearch Setup] Creating index for Message")
          Message.__elasticsearch__.create_index!(force: true)
          Message.import
          Rails.logger.info("[Elasticsearch Setup] Index created and imported successfully")
        else
          Rails.logger.info("[Elasticsearch Setup] Index already exists — skipping creation")
        end
      else
        Rails.logger.warn("[Elasticsearch Setup] Could not ping Elasticsearch at #{es_url}")
      end

    rescue => e
      Rails.logger.error("[Elasticsearch Setup] Failed: #{e.class} #{e.message}")
    end
  end
end
