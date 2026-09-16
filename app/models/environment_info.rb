require "etc"
require "socket"

# Collects runtime information about the current Ruby and Rails environment,
# grouped into sections similar to PHP's phpinfo().
class EnvironmentInfo
  SAFE_ENV_KEYS = %w[RAILS_ENV RACK_ENV PORT RAILS_MAX_THREADS WEB_CONCURRENCY TZ LANG HOSTNAME].freeze

  Section = Data.define(:heading, :rows)

  def self.sections
    new.sections
  end

  def sections
    [
      Section.new("Ruby", ruby_rows),
      Section.new("Rails", rails_rows),
      Section.new("Database", database_rows),
      Section.new("System", system_rows),
      Section.new("Environment", environment_rows)
    ]
  end

  private

  def ruby_rows
    {
      "Version" => RUBY_VERSION,
      "Patch level" => RUBY_PATCHLEVEL.to_s,
      "Release date" => RUBY_RELEASE_DATE,
      "Engine" => "#{RUBY_ENGINE} #{RUBY_ENGINE_VERSION}",
      "Platform" => RUBY_PLATFORM,
      "YJIT" => yjit_status,
      "RubyGems" => Gem::VERSION,
      "Bundler" => defined?(Bundler) ? Bundler::VERSION : "not loaded",
      "Loaded gems" => Gem.loaded_specs.size.to_s
    }
  end

  def rails_rows
    {
      "Version" => Rails.version,
      "Environment" => Rails.env,
      "Web server" => web_server,
      "Rack" => Rack.release,
      "Time zone" => Time.zone.name,
      "Eager load" => Rails.application.config.eager_load.to_s,
      "Cache store" => Rails.cache.class.name,
      "Active Job adapter" => ActiveJob::Base.queue_adapter.class.name,
      "Log level" => Rails.logger.level.to_s
    }
  end

  def database_rows
    pool = ActiveRecord::Base.connection_pool

    ActiveRecord::Base.with_connection do |connection|
      {
        "Adapter" => connection.adapter_name,
        "Server version" => connection.database_version.to_s,
        "Pool size" => pool.size.to_s,
        "Pending migrations" => pool.migration_context.needs_migration?.to_s
      }
    end
  rescue => e
    { "Adapter" => "unavailable", "Error" => e.class.name }
  end

  def system_rows
    {
      "Operating system" => RbConfig::CONFIG["host_os"],
      "Architecture" => RbConfig::CONFIG["host_cpu"],
      "Hostname" => Socket.gethostname,
      "Process ID" => Process.pid.to_s,
      "Processors" => Etc.nprocessors.to_s,
      "Server time" => Time.now.utc.rfc2822,
      "Process memory" => process_memory
    }
  end

  def environment_rows
    rows = SAFE_ENV_KEYS.filter_map { |key| [ key, ENV[key] ] if ENV.key?(key) }.to_h
    rows.empty? ? { "(none)" => "No allow-listed variables are set." } : rows
  end

  def yjit_status
    return "not available" unless defined?(RubyVM::YJIT)

    RubyVM::YJIT.enabled? ? "enabled" : "disabled"
  end

  def web_server
    if defined?(Puma::Const::PUMA_VERSION)
      "Puma #{Puma::Const::PUMA_VERSION}"
    else
      "unknown"
    end
  end

  def process_memory
    kilobytes = `ps -o rss= -p #{Process.pid}`.to_i
    kilobytes.positive? ? "#{(kilobytes / 1024.0).round(1)} MB" : "unknown"
  rescue Errno::ENOENT
    "unknown"
  end
end
