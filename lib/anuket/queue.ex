defprotocol Anuket.Queue do
  def push(queue, event)
  def handle_demand(queue, count)
  def handle_info(queue, message)
end
