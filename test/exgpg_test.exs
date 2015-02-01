defmodule ExgpgTest do
  use ExUnit.Case

 
  setup_all do
    Porcelain.reinit(Porcelain.Driver.Goon)
  end


  def fixture(name) do
    Path.join([__DIR__, "fixtures", name])    
  end

  def all_keyrings do
    [
      secret_keyring: fixture("test.sec"),
      keyring: fixture("test.pub")
    ]
  end

  def pub_keyrings do
    [
      keyring: fixture("test.pub")
    ]
  end


  def print(thing, label \\ "") do
    IO.puts label
    IO.inspect(thing)
    thing
  end


  test "can encrypt and then decrypt a string" do

    out = "hello world"
    |> Exgpg.encrypt([{:recipient, "test@test.com"} | all_keyrings])
    |> Enum.into("")
    |> Exgpg.decrypt(all_keyrings)
    |> Enum.into("")

    assert out == "hello world"
  end

  test "can encrypt and then decrypt a file" do
    path = fixture("enc-dec.txt")
    File.write(path, "hello world", [:write])

    assert {:path, path}
    |> Exgpg.encrypt([{:recipient, "test@test.com"} | all_keyrings])
    |> Enum.into("")
    |> Exgpg.decrypt(all_keyrings)
    |> Enum.into("") == "hello world"
  end


  test "get version" do
    out = Exgpg.version |> Enum.into("")

    assert String.contains?(out, "GnuPG")
    assert String.contains?(out, "License GPLv3+")

  end

  test "get a list of keys" do
    result = Exgpg.list_key(all_keyrings)
    assert result == [
      {
        ["pub", "u", "1024", "1", "6B056E5DF106EB16", "2015-01-26", "u", 
          "testtest (test) <test@test.com>", "scESC"
        ],
        ["sub", "u", "1024", "1", "8CF3FF6FEC6D9EB5", "2015-01-26", "e"]
      }
    ]
  end





  test "test symmetric encrypt/decrypt" do
    res = "test string"
    |> Exgpg.symmetric([passphrase: "hunter2"])
    |> Enum.into("")
    |> Exgpg.decrypt([passphrase: "hunter2"])
    |> Enum.into("")
    assert res == "test string"
  end


  test "can create a signed document" do
    {:ok, c} = File.cwd

    out = "hello world"
    |> Exgpg.encrypt([{:recipient, "test@test.com"}, {:sign, true} | all_keyrings])
    |> Enum.into("")
    |> Exgpg.verify(all_keyrings)
    |> Enum.into("")
  end


  @tag timeout: 300_000
  test "can make a new key" do
    out = Exgpg.gen_key(
      [
        key_type: "DSA",
        key_length: "1024",
        subkey_type: "ELG-E",
        subkey_length: "1024",
        name_real: "Foo Bar",
        name_email: "foo@bar.com",
        expire_date: "0",
        ctrl_pubring: "foo.pub",
        ctrl_secring: "foo.sec",
        ctrl_commit: "",
        ctrl_echo: "done" 
      ]
    )
  end
end
