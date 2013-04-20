class Action

  def self.params(*params)
    params.each do |param|
      define_method(param) do
        param(param)
      end
      private param
    end
  end

  def initialize(params)
    @params = params
  end

protected

  def transaction(&block)
    must_rollback = false
    $db.query "start transaction"
    begin
      yield
    rescue
      must_rollback = true
      raise
    ensure
      $db.query(must_rollback ? "rollback" : "commit")
    end
  end

  def multiply(a, b)
    (a * b / 100.0).round
  end

  def param(name)
    @params[name] || raise("missing param: #{name}")
  end

end