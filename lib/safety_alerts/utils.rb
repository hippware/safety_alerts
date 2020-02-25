module SafetyAlerts
  module Utils
    def self.hashify(obj)
      obj.instance_variables.each_with_object({}) do |var, hash|
        hash[var.to_s.delete("@")] = obj.instance_variable_get(var)
      end
    end
  end
end
