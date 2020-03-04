# frozen_string_literal: true

module SafetyAlerts
  # Utility functions that may be used in multiple places.
  module Utils
    def self.hashify(obj)
      obj.instance_variables.each_with_object({}) do |var, hash|
        hash[var.to_s.delete('@')] = obj.instance_variable_get(var)
      end
    end

    def self.print_exception(error)
      puts error
      print error.backtrace.join("\n")
    end
  end
end
