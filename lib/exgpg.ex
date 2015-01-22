defmodule Exgpg do

  @global_args [no_use_agent: true, batch: true]

  @commands [
    # gen_key: [{:gen_key, true} | @global_args],
    encrypt: {
      [{:encrypt, true} | @global_args],
      [in_suffix: "", out_suffix: ".gpg"]
    },
    decrypt: {
      Enum.concat([{:decrypt, true} | @global_args], [{:output, true}]),
      [in_suffix: "", out_suffix: ""]
    }
  ]

  defmodule AbnormalExit do
    defexception [:output, :status]

    def message(%{status: status, output: output}) do
      "exited with non-zero status (#{status})"
    end
  end

  Enum.each(@commands, fn {command, {args, modifiers}} ->
    def unquote(command)(input, options) do
      argv = OptionParser.to_argv(Enum.concat(unquote(args), options))
      run(input, argv, unquote(modifiers))
    end
  end)

  defp run({:file, input_path}, args, modifiers) do
    case System.find_executable("gpg") do
      nil -> raise :no_gpg
      exe -> 
        args = [input_path | Enum.reverse(args)] |> Enum.reverse
        IO.puts [exe | args] |> Enum.join(" ")

        File.rm("#{input_path}#{modifiers[:out_suffix]}")

        System.cmd(exe, args)
    end
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

  # defp run(input, args, modifiers) do

  #       path = "/tmp/#{UUID.uuid1()}#{modifiers[:in_suffix]}"
  #       :ok = File.write(path, input, [:exclusive, :write])

  #       IO.puts path

  #       File.stream!("#{path}#{modifiers[:out_suffix]}", [:read], :bytes)
  # end
  
  defp tmp(contents) do
    path = "/tmp/#{UUID.uuid1()}"
    :ok = File.write(path, input, [:exclusive, :write])
    path
  end

end
