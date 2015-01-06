defmodule BtCrawler.PeerHarvester do
  require Logger

  alias BtCrawler.DHT.Mainline
  alias BtCrawler.DB
  alias BtCrawler.Utils

  #####
  ## External API

  @doc """
  This function starts the DHT crawler.
  """
  def start(info_hash) do
    Logger.info "#{__MODULE__} start (#{inspect self} with #{info_hash})"
    get_peers(Utils.cfg(:bootstrap_node), 1, info_hash)
  end

  #####
  ## Interal API

  @doc """
  This function gets a fresh peer and starts a DHT find_node request
  to it. If this function gets executed n times, it will exit with
  :finish.
  """
  def get_peers(peer, n, info_hash) do
    ## check if n has reached its end
    if n == Utils.cfg(:number_of_requests_per_torrent) do
      Logger.info "finish"
      exit(:finish)
    end

    Logger.info "request peer: #{inspect peer} (#{n})"
    payload  = Mainline.get_peers(Utils.cfg(:node_id), Utils.hex_to_str(info_hash))
    incoming = Socket.UDP.open!

    Socket.Datagram.send(incoming, payload, peer)
    run(incoming, peer, n, info_hash)
  end


  defp run(incoming, peer, n, info_hash) do
    msg = receive_msg(incoming)
    handle(incoming, msg, peer, n, info_hash)
  end

  defp receive_msg(incoming) do
    Socket.Datagram.recv(incoming, 0, [timeout: Utils.cfg(:recv_timeout)])
  end

  @doc """
  This function handles an successful request. It prints the received
  message in hex and calls the Mainline DHT parser.
  """
  def handle(incoming, {:ok, {msg, _foo}}, peer, n, info_hash) do
    Logger.debug("Received message")
    Logger.debug("\n" <> PrettyHex.pretty_hex(msg))
    incoming |> Socket.close

    case Mainline.parse(msg) do
      %{error: [err_code, err_msg]} ->
        Logger.error "DHT response error #{err_code}: #{err_msg}"
      result ->
        Utils.tupel_to_ipstr(peer)
        |> DB.Query.get_id_from_socket
        |> add_dht_reponse(result)

        [torrent_id] = DB.Query.get_id_from_torrent(info_hash)

        add_peer(result[:nodes], n, "", torrent_id)
        add_peer(result[:values], n, info_hash, torrent_id)
    end

    restart(n, info_hash, torrent_id)
  end

  def restart(n, info_hash, torrent_id) do
    info_hash
    |> DB.Query.get_not_requested_peer(torrent_id)
    |> Utils.ipstr_to_tupel
    |> get_peers(n+1, info_hash)
  end


  @doc """
  This function takes a node_id and a dht response and creates a new
  entry in the table ml_dht_respones.
  """
  def add_dht_reponse([], _response), do: nil

  def add_dht_reponse([node_id | _tail], response) do
    entry = %DB.MlDHTResponses{payload_size: response[:size], nodes: length(response[:nodes]),values: length(response[:values]), version: response[:v], ml_dht_nodes_id: node_id}
    DB.Repo.insert(entry)
  end



  @doc """
  This function handles an unsuccessful request. It prints the error
  message and runs add_peer() again to start a new request.
  """
  def handle(incoming, {:error, reason}, peer, n, info_hash) do
    Logger.error "Peer #{inspect peer}: #{reason}"
    incoming |> Socket.close

    [torrent_id] = DB.Query.get_id_from_torrent(info_hash)
    restart(n, info_hash, torrent_id)
  end



  @doc """
  This function gets a list of peers and tries to add each of these
  into the database.
  """
  def add_peer([], _n, _info_hash, _torrent_id) do
  end


  def add_peer([peer | tail], n, info_hash, torrent_id) do
    Logger.info "peer added: #{inspect peer}"
    peer_str  = Utils.tupel_to_ipstr(peer)
    new_entry = %DB.MlDHTNodes{socket: peer_str, info_hash: info_hash, torrent_id: torrent_id}

    case DB.MlDHTNodes.validate(new_entry) do
      %{socket: [{:ok}]} ->
        new_entry |> DB.Repo.insert
      %{socket: [error: message]} ->
        Logger.error("Could not add new peer: #{message}")
    end

    add_peer(tail, n, info_hash, torrent_id)
  end

end
