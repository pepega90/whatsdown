defmodule WhatsdownWeb.ChatChannel do
  alias WhatsdownWeb.Presence
  alias Whatsdown.MessageStore
  use WhatsdownWeb, :channel

  @impl true
  def join("chat:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), "after_join")
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("chat:" <> private_chat, _payload, socket) do
    usernames = private_chat |> String.split(":")
    [user1, user2] = usernames |> Enum.sort()
    {:ok, socket |> assign(users: {user1, user2})}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client

  @impl true
  def handle_info("after_join", socket) do
    Presence.track(self(), "after_join", socket.id, %{})

    data =
      Presence.list("after_join")
      |> Enum.flat_map(fn {_id, %{metas: metas}} -> metas end) |> IO.inspect()

    push(socket, "list_user", %{data: data})

    {:noreply, socket}
  end

  @impl true
  def handle_in("new_user", %{"username" => username}, socket) do
    Presence.update(self(), "after_join", socket.id, %{
      id: inspect(socket.channel_pid),
      user: username
    }) |> IO.inspect()

    broadcast_from(socket, "new_user", %{new_user: username})
    {:noreply, socket}
  end

  def handle_in("send_dm", %{"sender" => sender, "msg" => msg}, socket) do
    {user1, user2} = socket.assigns.users
    message = %{sender: sender, message: msg}

    MessageStore.add_msg(user1, user2, message)

    broadcast(socket, "send_dm", %{sender: sender, msg: msg})
    {:noreply, socket}
  end

  def handle_in("get_history_chat", _payload, socket) do
    {user1, user2} = socket.assigns.users
    messages = MessageStore.get_message_history(user1, user2)
    push(socket, "get_chat_history", %{messages: messages})
    {:noreply, socket}
  end


  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (chat:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
