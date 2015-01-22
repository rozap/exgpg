defmodule ExgpgTest do
  use ExUnit.Case

  test "can encrypt a file" do
    IO.puts "#{System.cwd()}/test/data/hello_world"
    encrypted = Exgpg.encrypt(
      {:file, "#{System.cwd()}/test/data/hello_world"}, 
      [recipient: "chrisd1891@gmail.com"]
    )
    IO.inspect encrypted
  end

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

end
