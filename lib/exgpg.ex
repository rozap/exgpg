defmodule Exgpg do

  @global_args [no_use_agent: true, batch: true, no_default_keyring: true]

  @without_input [
    list_key: [{:with_colons, true} | @global_args],
    version: []
  ]

  @with_input [
    gen_key: @global_args,
    encrypt: @global_args,
    decrypt: @global_args,
    symmetric: @global_args
  ]

  defmodule AbnormalExit do
    defexception [:output, :status]

    def message(%{status: status, output: _}) do
      "exited with non-zero status (#{status})"
    end
  end

  Enum.each(@without_input, fn {command, args} ->
    def unquote(command)(user_args \\ []) do
      args = [{unquote(command), true} | unquote(args)]
      {nil, args, user_args}
      |> run(unquote(command))
      |> adapt_out(unquote(command))
    end
  end)

  Enum.each(@with_input, fn {command, args} ->
    def unquote(command)(input \\ nil, user_args \\ []) do
      args = [{unquote(command), true} | unquote(args)]
      {input, args, user_args}
      |> adapt_in(unquote(command))
      |> run(unquote(command))
      |> adapt_out(unquote(command))
    end
  end)

  defp run({nil, args, user_args}, _) do
    spawn_opts = [out: :stream]
    gpg(args, user_args, spawn_opts)
  end

  defp run({input, args, user_args}, _) do
    spawn_opts = [in: input, out: :stream]
    gpg(args, user_args, spawn_opts)
  end

  defp gpg(args, user_args, spawn_opts) do
    argv = args
    |> Enum.concat(user_args)
    |> OptionParser.to_argv
    IO.puts "Running  gpg #{Enum.join(argv, " ")}"
    Porcelain.spawn("gpg", argv, spawn_opts)
  end

  def adapt_in({_input, _args, user_args}, :gen_key) do
    input = user_args
    |> Enum.filter(fn {key, _} -> key != :gen_key end)    
    |> Enum.map(fn {key, val} -> {Atom.to_string(key), val} end)
    |> Enum.map(fn {key, val} -> to_genkey(key, val) end)
    |> Enum.join("\n")
    IO.puts input
    {input, [{:gen_key, true} | @global_args], []}
  end

  def adapt_in({input, args, user_args}, _), do: {input, args, user_args}

  def adapt_out(result, :list_key) do
    result.out
    |> Enum.into("")
    |> String.split("\n")
    |> Enum.drop(1)
    |> Enum.map(fn s ->
      s
      |> String.split(":")
      |> Enum.filter(&(&1 != ""))
    end)
    |> Enum.filter(&(&1 != []))
    |> Enum.chunk(2)
    |> Enum.map(&(List.to_tuple &1))
  end

  def adapt_out(proc, _) do
    Porcelain.Process.send_input(proc, "")
    proc.out
  end


  defp to_genkey("ctrl_" <> rest, ""), do: "%" <> rest
  defp to_genkey("ctrl_" <> rest, val) do
    ("%" <> rest) <> (" " <> val)
  end

  defp to_genkey(key, val) do
    (key
     |> String.split("_")
     |> Enum.map(&String.capitalize &1)
     |> Enum.join("-")) <> (": " <> "#{val}")
  end

end
