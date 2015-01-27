defmodule Exgpg do

  @global_args [no_use_agent: true, batch: true, no_default_keyring: true]

  @commands [
    # gen_key: [{:gen_key, true} | @global_args],
    list_key: [{:with_colons, true} | @global_args],
    encrypt: @global_args,
    decrypt: @global_args
  ]

  defmodule AbnormalExit do
    defexception [:output, :status]

    def message(%{status: status, output: output}) do
      "exited with non-zero status (#{status})"
    end
  end

  Enum.each(@commands, fn {command, args} ->
    def unquote(command)(user_args \\ [], input \\ nil) do
      args = [{unquote(command), true} | Enum.concat(unquote(args), user_args)]
      
      input
      |> adapt_in(unquote(command))
      |> run(args) 
      |> adapt_out(unquote(command))
    end
  end)


  defp run(nil, args) do
    spawn_opts = [out: :stream]
    gpg(args, spawn_opts)
  end

  defp gpg(args, spawn_opts \\ []) do
    argv = args
    |> OptionParser.to_argv
    IO.puts "Running  gpg #{Enum.join(argv, " ")}"
    Porcelain.spawn("gpg", argv, spawn_opts)
  end

  def adapt_in(input, _command), do: input

  def adapt_out(result, :list_key) do
    i = result.out
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





  defp to_genkey("ctrl_" <> rest, ""), do: "%" <> rest
  defp to_genkey("ctrl_" <> rest, val) do
    ("%" <> rest) <> (" " <> val)
  end

  defp to_genkey(key, val) do
    (key
     |> String.split("_")
     |> Enum.map(&String.capitalize &1)
     |> Enum.join("-")) <> (": " <> val)
  end

  def keylist_to_filecontents(items) do
    items
      |> Enum.map(fn {key, val} -> {Atom.to_string(key), val} end)
      |> Enum.map(fn {key, val} -> to_genkey(key, val) end)
      |> Enum.join("\n")
  end

end
