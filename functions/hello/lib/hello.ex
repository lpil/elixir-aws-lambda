defmodule Hello do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Hello.Worker.start_link(arg1, arg2, arg3)
      worker(Hello.Main, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Hello.Main do
  @behaviour AwsLambda.ShimClient

  def start_link do
    AwsLambda.ShimClient.start_link(__MODULE__, :this_is_mod_state)
  end

  def init(state) do
    state
  end

  def handle_invocation(data, state) do
    {:ok, %{data: data, state: state}, state}
  end
end

defmodule AwsLambda.ShimClient do
  use GenServer

  defstruct [:port, :module, :module_state]

  @type input :: any
  @type reply :: any
  @type state :: any
  @callback init(any) :: {:ok, state}
  @callback handle_invocation(input, state) :: {:ok, reply, state}
                                             | {:error, reply, state}

  def start_link(mod, mod_args) do
    GenServer.start_link(__MODULE__, {mod, mod_args})
  end

  #
  # Callbacks
  #

  def init({mod, mod_args}) do
    port = Port.open({:fd, 0, 1}, [:binary])
    mod_state = mod.init(mod_args)
    state = %__MODULE__{port: port,
                        module: mod,
                        module_state: mod_state}
    {:ok, state}
  end

  def handle_info({port, {:data, data}}, state = %{port: port}) do
    input = decode_json(data)
    # TODO error tuple handling
    {:ok, resp, mod_state} =
      state.module.handle_invocation(input, state.module_state)
    output = Poison.encode!(resp) <> "\n"
    Port.command(port, output)
    {:noreply, %{state | module_state: mod_state}}
  end

  defp decode_json(json) do
    case Poison.decode(json) do
      {:ok, res} -> res
      _ -> nil
    end
  end
end
