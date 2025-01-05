defmodule Whatsdown.MessageStore do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :ets.new(:message_store, [:public, :named_table, :set])
    {:ok, nil}
  end

  def add_msg(user1, user2, message) do
    GenServer.call(__MODULE__, {:add_msg, user1, user2, message})
  end

  def get_message_history(user1,user2) do
    GenServer.call(__MODULE__, {:get_history, user1,user2})
  end

  @impl true
  def handle_call({:add_msg, user1,user2, message}, _from, state) do
    key = {Enum.min([user1,user2]), Enum.max([user1,user2])}
    case :ets.lookup(:message_store, key) do
      [] -> :ets.insert(:message_store, {key, [message]})
      [{^key, messages}] -> :ets.insert(:message_store, {key, [message | messages]})
    end

    {:reply, :ok, state}
  end


  @impl true
  def handle_call({:get_history, user1,user2}, _from, state) do
    key = {Enum.min([user1,user2]), Enum.max([user1,user2])}
    messages = case :ets.lookup(:message_store, key) do
       [{^key, messages}] -> Enum.reverse(messages)
       [] -> []
    end
    {:reply, messages, state}
  end
end
