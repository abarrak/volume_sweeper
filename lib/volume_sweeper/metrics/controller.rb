
module Prometheus
  module Controller
    # TODO: ..
    def self.setup_metrics
      metrics_dir = Rails.root.join 'tmp', 'prometheus'
      Dir["#{metrics_dir}/*.bin"].each { |file_path| File.unlink(file_path) }
      Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: metrics_dir)

      @prometheus ||= Prometheus::Client.registry

      register_gauge :available_block_volume_count,
                     'The total of unattached block volumes.',
                     :available_block_volume_count
      register_gauge :released_pv_count,
                     'The total of released persistent volumes.',
                     :released_pv_count
      register_gauge :inactive_block_volume_count,
                     'The number of block volumes count that are unused (no instance or PV bound).',
                     :inactive_block_volume_count

    end

    def self.clear_metrics
      @prometheus ||= Prometheus::Client.registry
      unregister_gauge :available_block_volume_count
      unregister_gauge :released_pv_count
      unregister_gauge :inactive_block_volume_count
    end

    def self.register_gauge key, docstring, *labels
      gauge = Prometheus::Client::Gauge.new key, docstring: docstring, labels: labels
      @prometheus.register(gauge)
      gauge
    end

    def self.unregister_gauge key
      @prometheus.unregister key
    end
  end
end
