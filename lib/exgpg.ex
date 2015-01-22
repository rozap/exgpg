defmodule Exgpg do

  @global_args [no_use_agent: true, batch: true]
  @commands [
    gen_key: [{:gen_key, true} | @global_args],
    encrypt: [{:encrypt, true} | @global_args]
  ]

  Enum.each(@commands, fn {command, args} ->
    def unquote(command)(options) do
      argv = OptionParser.to_argv(Enum.concat(unquote(args), options))
      run(argv)
    end
  end)

  defp run(args) do
    IO.puts "Running #{inspect args}"
    case System.find_executable("gpg") do
      nil -> raise :no_gpg
      exe -> 
        opts = [:exit_status, :stderr_to_stdout, :in, :binary, :eof, :hide, args: args]
        IO.inspect opts
        port = Port.open({:spawn_executable, exe}, opts)

    end

  end
  
  defp wait(port), do: wait(port, "")

  defp wait(port, acc) do
    receive do
      {^port, {:data, data}} ->
        IO.puts "RECV"
        IO.inspect data
        wait(port, acc + data)
      {^port, :eof} ->
        send port, {self, :close}
        receive do
          { ^port, { :exit_status, 0 } } ->
            acc
          { ^port, { :exit_status, status } } ->
            raise :bad_exit
        end
    end
  end

end
