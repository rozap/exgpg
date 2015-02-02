defmodule ExgpgTest do
  use ExUnit.Case

 
  setup_all do
    Porcelain.reinit(Porcelain.Driver.Goon)
  end

  ##
  # This will re-init all the fixtures, as some will change 
  # due to tests adding keys and such
  setup do
    source = Path.join([__DIR__, "fixtures/originals"])    
    dest = Path.join([__DIR__, "fixtures"])    
    source
    |> File.ls!
    |> Enum.each(fn f -> 
      File.cp!(
        Path.join([source, f]),
        Path.join([dest, f])
      )
    end)
  end


  def fixture(name) do
    Path.join([__DIR__, "fixtures", name])
  end

  def output(proc) do
    proc.out
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

  def key_from_email(email) do
    res = all_keyrings
    |> Exgpg.list_key
    |> Enum.find(false, fn {pub, _} -> 
      Enum.find(pub, false, fn st -> 
        String.contains?(st, email)
      end)
    end)
  end


  test "can encrypt and then decrypt a string" do
    out = "hello world"
    |> Exgpg.encrypt([{:recipient, "test@test.com"} | all_keyrings])
    |> output
    |> Exgpg.decrypt(all_keyrings)
    |> output
    |> Enum.into("")

    assert out == "hello world"
  end

  test "can encrypt and then decrypt a file path" do
    path = fixture("hello_world")
    File.write(path, "hello world", [:write])

    assert {:path, path}
    |> Exgpg.encrypt([{:recipient, "test@test.com"} | all_keyrings])
    |> output
    |> Exgpg.decrypt(all_keyrings)
    |> output
    |> Enum.into("") == "hello world"
  end

  test "can encrypt and then decrypt a file" do
    path = fixture("hello_world")
    File.write(path, "hello world", [:write])
    {:ok, file} = File.open(path, [:read])
    assert {:file, file}
    |> Exgpg.encrypt([{:recipient, "test@test.com"} | all_keyrings])
    |> output
    |> Exgpg.decrypt(all_keyrings)
    |> output
    |> Enum.into("") == "hello world"
  end

  test "get version" do
    out = Exgpg.version |> output |> Enum.into("")
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


  test "can export an ascii armored key" do
    result = "test@test.com"
    |> Exgpg.export_key([{:armor, true} | all_keyrings])
    |> output
    |> Enum.into("")
    
    expected = fixture("test_armor_export")
    |> File.open!([:read])
    |> IO.read(:all)

    assert expected == result
  end


  test "can import a key" do
    assert key_from_email("chrisd1891@gmail.com") == false

    {:path, fixture("mine.gpg")}
    |> Exgpg.import_key(all_keyrings)
    |> output
    |> Enum.into("")
    |> IO.puts

    assert key_from_email("chrisd1891@gmail.com") != false
  end



  test "symmetric encrypt/decrypt" do
    res = "test string"
    |> Exgpg.symmetric([passphrase: "hunter2"])
    |> output
    |> Exgpg.decrypt([passphrase: "hunter2"])
    |> output
    |> Enum.into("")
    assert res == "test string"
  end


  test "can verify a signed document" do
    path = fixture("hello_world.sig")
    {:ok, proc} = Exgpg.verify({:path, path}, all_keyrings)
    assert proc.status == 0    
    {:ok, proc} = Exgpg.verify("foobar", all_keyrings)
    assert proc.status == 2
  end

  test "can sign and verify" do
    {:ok, proc} = "hello world"
    |> Exgpg.sign([{:recipient, "test@test.com"} | all_keyrings])
    |> output
    |> Exgpg.verify([{:recipient, "test@test.com"} | all_keyrings])
    assert proc.status == 0
  end


 test "can sign and decrypt" do
    out = "hello world"
    |> Exgpg.sign([{:recipient, "test@test.com"} | all_keyrings])
    |> output
    |> Exgpg.decrypt([{:recipient, "test@test.com"} | all_keyrings])
    |> output
    |> Enum.into("")
    assert out == "hello world"
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
