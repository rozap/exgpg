defmodule Exgpg do

  @global_args [no_use_agent: true, batch: true]
  @commands [
    # gen_key: [{:gen_key, true} | @global_args],
    encrypt: [{:encrypt, true} | @global_args]
  ]

  defmodule AbnormalExit do
    defexception [:output, :status]

    def message(%{status: status, output: output}) do
      "exited with non-zero status (#{status})"
    end
  end



  Enum.each(@commands, fn {command, args} ->
    def unquote(command)(input, options) do
      argv = OptionParser.to_argv(Enum.concat(unquote(args), options))
      run(input, argv)
    end
  end)

  defp run(input, args) do
    IO.puts "Running #{inspect args}"
    case System.find_executable("gpg") do
      nil -> raise :no_gpg
      exe -> 
        opts = [:use_stdio, :exit_status, :binary, :hide, args: args]

        port = Port.open({:spawn_executable, exe}, opts)
        # send(port, {self, {:command, input}})
        Port.command(port, input)
        wait(port)
    end

  end
  
  defp wait(port), do: wait(port, "")

  defp wait(port, acc) do
    receive do
      {^port, {:data, data}} ->
        IO.inspect data
        wait(port, acc <> data)
      {^port, { :exit_status, 0 } } ->
        IO.puts "Finished"
        acc
      {^port, { :exit_status, status } } ->
        raise %AbnormalExit{status: status, output: acc}
    end
  end

end
