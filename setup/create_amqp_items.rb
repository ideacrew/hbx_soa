class SetupAmqpTasks
  def initialize
    conn = Bunny.new(ExchangeInformation.amqp_uri)
    conn.start
    @ch = conn.create_channel
    @ch.prefetch(1)
  end

  def queue(q)
    @ch.queue(q, :durable => true)
  end

  def exchange(e_type, name)
    @ch.send(e_type.to_sym, name, {:durable => true})
  end

  def logging_queue(ec, name)
    q_name = "#{ec.hbx_id}.#{ec.environment}.q.#{name}"
    @ch.queue(q_name, :durable => true)
  end

  def run
    ec = ExchangeInformation

    queue(ec.invalid_argument_queue)
    queue(ec.processing_failure_queue)
    eeh_q = queue(Listeners::EnrollmentEventHandler.queue_name)

    event_ex = exchange("topic", ec.event_exchange)
    direct_ex = exchange("direct", ec.request_exchange)

    eeh_q.bind(event_ex, :routing_key => "enrollment.individual.initial_enrollment")
    eeh_q.bind(event_ex, :routing_key => "enrollment.individual.renewal")

    emp_qhps = logging_queue(ec, "recording.ee_qhp_plan_selected")
    ind_qhps = logging_queue(ec, "recording.ind_qhp_plan_selected")
    emp_qhps.bind(event_ex, :routing_key => "employer_employee.qhp_selected")
    ind_qhps.bind(event_ex, :routing_key => "individual.qhp_selected")
  end
end

SetupAmqpTasks.new.run
