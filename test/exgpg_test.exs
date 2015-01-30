defmodule ExgpgTest do
  use ExUnit.Case

 
  setup_all do
    Porcelain.reinit(Porcelain.Driver.Goon)
  end

  test "get version" do
    out = Exgpg.version |> Enum.into("")

    assert String.contains?(out, "GnuPG")
    assert String.contains?(out, "License GPLv3+")

  end

  test "get a list of keys" do
    {:ok, c} = File.cwd
    result = Exgpg.list_key(
      [
        secret_keyring: "#{c}/test/data/test.sec",
        keyring: "#{c}/test/data/test.pub",
      ]
    )
    assert result == [
      {
        ["pub", "u", "1024", "1", "6B056E5DF106EB16", "2015-01-26", "u", 
          "testtest (test) <test@test.com>", "scESC"
        ],
        ["sub", "u", "1024", "1", "8CF3FF6FEC6D9EB5", "2015-01-26", "e"]
      }
    ]
  end


 test "can encrypt and then decrypt a string" do
    {:ok, c} = File.cwd

    keyrings = [
      secret_keyring: "#{c}/test/data/test.sec",
      keyring: "#{c}/test/data/test.pub"
    ]

    out = "hello world"
    |> Exgpg.encrypt([{:recipient, "test@test.com"} | keyrings])
    |> Enum.into("")
    |> Exgpg.decrypt(keyrings)
    |> Enum.into("")

    assert out == "hello world"
  end


  test "test symmetric encrypt/decrypt" do
    res = "test string"
    |> Exgpg.symmetric([passphrase: "hunter2"])
    |> Enum.into("")
    |> Exgpg.decrypt([passphrase: "hunter2"])
    |> Enum.into("")
    assert res == "test string"
  end



  # @tag timeout: 300_000
  # test "can make a new key" do
  #   out = Exgpg.gen_key(
  #     [
  #       key_type: "DSA",
  #       key_length: "1024",
  #       subkey_type: "ELG-E",
  #       subkey_length: "1024",
  #       name_real: "Foo Bar",
  #       name_email: "foo@bar.com",
  #       expire_date: "0",
  #       ctrl_pubring: "foo.pub",
  #       ctrl_secring: "foo.sec",
  #       ctrl_commit: "",
  #       ctrl_echo: "done" 
  #     ]
  #   )
  # end
end
