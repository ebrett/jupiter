# Circuit breaker pattern implementation for fault-tolerant services
module CircuitBreaker
  extend ActiveSupport::Concern

  class CircuitOpenError < StandardError; end

  included do
    class_attribute :circuit_breaker_config, default: {}
  end

  class_methods do
    def circuit_breaker(method_name, failure_threshold: 5, timeout: 60.seconds, fallback: nil)
      circuit_breaker_config[method_name] = {
        failure_threshold: failure_threshold,
        timeout: timeout,
        fallback: fallback
      }

      # Create wrapped method
      original_method = instance_method(method_name)

      define_method(method_name) do |*args, **kwargs, &block|
        circuit = circuit_for(method_name)

        if circuit.open?
          handle_circuit_open(method_name, *args, **kwargs)
        else
          begin
            result = original_method.bind(self).call(*args, **kwargs, &block)
            circuit.success!
            result
          rescue => error
            circuit.failure!
            if circuit.open?
              Rails.logger.error "Circuit breaker opened for #{self.class}##{method_name} after #{circuit.failure_count} failures"
              handle_circuit_open(method_name, *args, **kwargs)
            else
              raise error
            end
          end
        end
      end
    end
  end

  private

  def circuit_for(method_name)
    @circuits ||= {}
    @circuits[method_name] ||= Circuit.new(
      self.class.circuit_breaker_config[method_name][:failure_threshold],
      self.class.circuit_breaker_config[method_name][:timeout]
    )
  end

  def handle_circuit_open(method_name, *args, **kwargs)
    config = self.class.circuit_breaker_config[method_name]

    if config[:fallback] && respond_to?(config[:fallback], true)
      send(config[:fallback], *args, **kwargs)
    else
      raise CircuitOpenError, "Circuit breaker is open for #{self.class}##{method_name}"
    end
  end

  # Internal circuit state management
  class Circuit
    attr_reader :failure_count, :last_failure_time

    def initialize(failure_threshold, timeout)
      @failure_threshold = failure_threshold
      @timeout = timeout
      @failure_count = 0
      @last_failure_time = nil
      @mutex = Mutex.new
    end

    def open?
      @mutex.synchronize do
        return false if @failure_count < @failure_threshold
        return false if @last_failure_time.nil?

        # Check if timeout has passed
        if Time.current - @last_failure_time > @timeout
          reset!
          false
        else
          true
        end
      end
    end

    def success!
      @mutex.synchronize do
        @failure_count = 0
        @last_failure_time = nil
      end
    end

    def failure!
      @mutex.synchronize do
        @failure_count += 1
        @last_failure_time = Time.current
      end
    end

    private

    def reset!
      @failure_count = 0
      @last_failure_time = nil
    end
  end
end
