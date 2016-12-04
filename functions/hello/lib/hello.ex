defmodule Hello do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Hello.Worker.start_link(arg1, arg2, arg3)
      worker(Hello.StdioListener, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)
  end
end


# Port = open_port({fd, 0, 1}, [in, binary, {line, 4096}]),

defmodule Hello.StdioListener do
  use GenServer

  defstruct [:port]

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  #
  # Callbacks
  #

  def init(_) do
    stdio = {:fd, 0, 1}
    port = Port.open(stdio, [:binary, :in])
    {:ok, %__MODULE__{port: port}}
  end

  def handle_info({port, {:data, data}}, state = %{port: port}) do
    IO.write """
    {"value":{"hello":""}}
    """
    {:noreply, state}
  end
end
