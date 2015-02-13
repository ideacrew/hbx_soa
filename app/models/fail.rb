class Fail                                                               
  def initialize(&on_fail)
    if on_fail.nil?
      @fail_blk = lambda { |x| x }
    else
      @fail_blk = on_fail
    end
    @procs = []
  end

  def bind(&blk)
    @procs << blk
    self
  end

  def call(value)
    failure_caught = catch(:fail) do
      result = @procs.inject(value) do |res, p|
        p.call(res)
      end
      return result
    end
    @fail_blk.call(failure_caught)
  end
end
