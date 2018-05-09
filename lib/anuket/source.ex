defprotocol Anuket.Source do
  def init(source)
  def handle_demand(source, demand)
  def handle_info(source, message)
end
