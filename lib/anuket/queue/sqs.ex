defmodule Anuket.Queue.SQS do
  defstruct demand: 0,
            retry_timeout: 1_000,
            timer: nil,
            queue: nil

  require Logger

  defmodule ObjectCreated do
    defstruct [:bucket, :key, :etag, :time]

    defimpl Anuket.Event do
      def type(_) do
        :created
      end
    end

    defimpl String.Chars do
      def to_string(%{bucket: bucket, key: key}) do
        "s3://#{bucket}/#{key}"
      end
    end
  end

  defmodule ObjectDeleted do
    defstruct [:bucket, :key, :time]

    defimpl Anuket.Event do
      def type(_) do
        :deleted
      end
    end

    defimpl String.Chars do
      def to_string(%{bucket: bucket, key: key}) do
        "s3://#{bucket}/#{key}"
      end
    end
  end

  def new(opts) do
    %__MODULE__{
      queue: Keyword.fetch!(opts, :queue),
      retry_timeout: Keyword.get(opts, :retry_timeout, 1_000)
    }
  end

  defimpl Anuket.Queue do
    def push(%{queue: queue} = q, event) do
      res = queue
      |> ExAws.SQS.send_message(Poison.encode!(event))
      |> ExAws.request!()

      Logger.debug("SQS: #{inspect(res)}")

      q
    end

    def handle_demand(%{queue: queue, demand: prev_demand, timer: nil}, demand) do
      dispatch_events(queue, prev_demand + demand, [])
    end

    def handle_demand(%{demand: prev_demand} = queue, demand) do
      {[], %{queue | demand: prev_demand + demand}}
    end

    def handle_info(%{queue: queue, demand: demand}, :sqs_retry) do
      dispatch_events(queue, demand, [])
    end

    def handle_info(state, _message) do
      {[], state}
    end

    defp dispatch_events(queue, 0, events) do
      {Enum.to_list(events), %@for{queue: queue, demand: 0}}
    end

    defp dispatch_events(queue, demand, events) do
      queue
      |> ExAws.SQS.receive_message(
        max_number_of_messages: max(1, min(10, demand)),
        wait_time_seconds: 0
      )
      |> ExAws.request()
      |> case do
        {:ok, %{body: %{messages: []}}} ->
          Logger.debug("SQS: #{queue} empty")
          timer = :timer.send_after(20_000, :sqs_retry)
          {Enum.to_list(events), %@for{queue: queue, demand: demand, timer: timer}}

        {:ok, %{body: %{messages: messages}}} ->
          events =
            Stream.concat(
              events,
              Stream.map(messages, &handle_message(&1, queue))
            )

          dispatch_events(queue, demand - length(messages), events)
      end
    end

    defp handle_message(%{body: body, receipt_handle: receipt}, queue) do
      body
      |> Poison.decode()
      |> case do
        {:ok, event} ->
          {handle_event(event), &handle_receipt(queue, receipt, &1)}
      end
    end

    defp handle_event(%{
           "Records" => [
             %{
               "eventName" => "ObjectCreated:Put",
               "eventTime" => time,
               "s3" => %{
                 "bucket" => %{"name" => bucket},
                 "object" => %{"key" => key, "eTag" => etag}
               }
             }
           ]
         }) do
      {:ok, time, _} = DateTime.from_iso8601(time)

      %@for.ObjectCreated{
        bucket: bucket,
        key: URI.decode(key),
        etag: etag,
        time: time
      }
    end

    defp handle_event(%{
           "Records" => [
             %{
               "eventName" => "ObjectRemoved:Delete",
               "eventTime" => time,
               "s3" => %{
                 "bucket" => %{"name" => bucket},
                 "object" => %{"key" => key}
               }
             }
           ]
         }) do
      {:ok, time, _} = DateTime.from_iso8601(time)

      %@for.ObjectDeleted{
        bucket: bucket,
        key: URI.decode(key),
        time: time
      }
    end

    defp handle_event(event) do
      event
    end

    defp handle_receipt(queue, receipt, :ok) do
      ExAws.SQS.delete_message(queue, receipt)
      |> ExAws.request()
    end
  end
end
