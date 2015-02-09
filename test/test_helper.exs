
defmodule Exgpg.Test.Utils do
   def gen_key_for(name) do
    {:ok, proc} = Exgpg.gen_key(
      [
        key_type: "DSA",
        key_length: "1024",
        subkey_type: "ELG-E",
        subkey_length: "1024",
        name_real: "#{name} #{name}",
        name_email: "#{name}@#{name}.com",
        expire_date: "0",
        ctrl_pubring: rings_for(name)[:keyring],
        ctrl_secring: rings_for(name)[:secret_keyring],
        ctrl_commit: "",
        ctrl_echo: "done"
      ]
    )
    proc
  end

  def fixture(name) do
    Path.join([__DIR__, "fixtures", name])
  end

  def output(proc) do
    proc.out
  end

  def err_output(proc) do
    proc.err
  end

  def rings_for(name) do
    [
      secret_keyring: fixture("#{name}.sec"),
      keyring: fixture("#{name}.pub")
    ]
  end

  def pub_ring_for(name) do
    [_, k] = rings_for(name)
    k
  end

  def sec_ring_for(name) do
    [s, _] = rings_for(name)
    s
  end


  def print(thing, label \\ "") do
    IO.puts label
    IO.inspect(thing)
    thing
  end

  def key_from_email(name, email) do
    rings_for(name)
    |> Exgpg.list_key
    |> Enum.find(false, fn {pub, _} -> 
      Enum.find(pub, false, fn st -> 
        String.contains?(st, email)
      end)
    end)
  end


end

ExUnit.start()
