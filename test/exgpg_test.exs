defmodule ExgpgTest do
  use ExUnit.Case

 
  setup_all do
    Porcelain.reinit(Porcelain.Driver.Goon)

    gen_key_for("alice")
    gen_key_for("bob")

    # result = "alice@alice.com"
    # |> Exgpg.export_key([{:armor, true} | rings_for("alice")])
    # |> output
    # |> Enum.into("")
    # |> Exgpg.import_key(rings_for("alice"))
    # |> output
    # |> Enum.into("")
    # |> IO.puts


    {:ok, %{}}
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
    assert proc.status == 0
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
    res = rings_for(name)
    |> Exgpg.list_key
    |> Enum.find(false, fn {pub, _} -> 
      Enum.find(pub, false, fn st -> 
        String.contains?(st, email)
      end)
    end)
  end


  test "can get an error message when things don't work" do
    proc = "hello world"
    |> Exgpg.encrypt([{:recipient, "alice@alice.com"} | rings_for("alice")])
    |> output
    |> Exgpg.decrypt([pub_ring_for("alice")])
    |> Porcelain.Process.await

    {:ok, s} = proc
    assert String.contains?(s.err, "secret key not available")
  end

  test "can encrypt and then decrypt a string" do
    out = "hello world"
    |> Exgpg.encrypt([{:recipient, "alice@alice.com"} | rings_for("alice")])
    |> output
    |> Exgpg.decrypt(rings_for("alice"))
    |> output
    |> Enum.into("")

    assert out == "hello world"
  end

  test "can encrypt and then decrypt a file path" do
    path = fixture("hello_world")
    File.write(path, "hello world", [:write])

    assert {:path, path}
    |> Exgpg.encrypt([{:recipient, "bob@bob.com"}, pub_ring_for("bob")])
    |> output
    |> Exgpg.decrypt(rings_for("bob"))
    |> output
    |> Enum.into("") == "hello world"
  end

  test "can encrypt and then decrypt a file" do
    path = fixture("hello_world")
    File.write(path, "hello world", [:write])
    {:ok, file} = File.open(path, [:read])
    assert {:file, file}
    |> Exgpg.encrypt([{:recipient, "alice@alice.com"}, pub_ring_for("alice")])
    |> output
    |> Exgpg.decrypt(rings_for("alice"))
    |> output
    |> Enum.into("") == "hello world"
  end

  test "get version" do
    out = Exgpg.version |> output |> Enum.into("")
    assert String.contains?(out, "GnuPG")
    assert String.contains?(out, "License GPLv3+")
  end

  test "get a list of keys" do
    res = Exgpg.list_key(rings_for("alice"))
  end


  test "can export an ascii armored key" do
    result = "alice@alice.com"
    |> Exgpg.export_key([{:armor, true} | rings_for("alice")])
    |> output
    |> Enum.into("")
    
    "-----BEGIN PGP PUBLIC KEY BLOCK-----" <> _rest = result
  end


  test "can import a key" do
    # assert key_from_email("chrisd1891@gmail.com") == false

    {:path, fixture("mine.gpg")}
    |> Exgpg.import_key(rings_for("alice"))
    |> output
    |> Enum.into("")
    |> IO.puts

    assert key_from_email("alice", "chrisd1891@gmail.com") != false
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

  # Since we're using trust mode always, this won't work?
  # test "can verify a signed document" do
  #   path = fixture("hello_world.sig")
  #   {:ok, proc} = Exgpg.verify({:path, path}, rings_for("alice"))
  #   assert proc.status == 0    
  #   {:ok, proc} = Exgpg.verify("foobar", rings_for("alice"))
  #   assert proc.status == 2
  # end

  test "can sign and verify" do
    {:ok, proc} = "hello world"
    |> Exgpg.sign([{:recipient, "alice@alice.com"} | rings_for("alice")])
    |> output
    |> Exgpg.verify([{:recipient, "alice@alice.com"} | rings_for("alice")])
    assert proc.status == 0
  end


  test "can sign and decrypt" do
    out = "hello world"
    |> Exgpg.sign([{:recipient, "alice@alice.com"} | rings_for("alice")])
    |> output
    |> Exgpg.decrypt([{:recipient, "alice@alice.com"} | rings_for("alice")])
    |> output
    |> Enum.into("")
    assert out == "hello world"
  end


  test "sending invalid stuff to gen key" do
    {:ok, proc} = Exgpg.gen_key([nope: "lol"])
    assert proc.status == 2
  end

  #
  # This can take quite a while (~5 minutes), so install rng-tools to generate
  # more entropy and it will complete within the timeout period
  test "can make a new key" do
    pub_ring = fixture("foo.pub")
    {:ok, proc} = Exgpg.gen_key(
      [
        key_type: "DSA",
        key_length: "1024",
        subkey_type: "ELG-E",
        subkey_length: "1024",
        name_real: "Foo Bar",
        name_email: "foo@bar.com",
        expire_date: "0",
        ctrl_pubring: pub_ring,
        ctrl_secring: fixture("foo.sec"),
        ctrl_commit: "",
        ctrl_echo: "done"
      ]
    )

    assert proc.status == 0
    [{result, _}] = Exgpg.list_key([keyring: pub_ring])
    assert "Foo Bar <foo@bar.com>" in result
    assert "pub" in result
  end
end
