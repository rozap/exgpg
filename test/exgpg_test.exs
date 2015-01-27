defmodule ExgpgTest do
  use ExUnit.Case

  # test "can encrypt a string" do
  #   proc = Exgpg.encrypt("hello world", 
  #     [recipient: "chrisd1891@gmail.com"]
  #   )
  #   {:ok, cwd} = File.cwd
  #   name = "can_encrypt.out"
  #   actual = File.stream!("#{cwd}/test/temp/#{name}")



  #   assert actual == expected 
  #   # proc.out
  #   # |> Stream.into()
  #   # |> Stream.run
  # end

  test "keylist to filecontents" do
    result = Exgpg.keylist_to_filecontents([
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
    ])

    expected = [
     "Key-Type: DSA",
     "Key-Length: 1024",
     "Subkey-Type: ELG-E",
     "Subkey-Length: 1024",
     "Name-Real: Foo Bar",
     "Name-Email: foo@bar.com",
     "Expire-Date: 0",
     "%pubring foo.pub",
     "%secring foo.sec",
     "%commit",
     "%echo done"] |> Enum.join("\n")

     assert expected == result
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

  test "can make a new key" do
    {:ok, c} = File.cwd
    result = Exgpg.list_key(
      [
        secret_keyring: "#{c}/test/data/test_create.sec",
        keyring: "#{c}/test/data/test_create.pub",
      ]
    )
    
  end
end
