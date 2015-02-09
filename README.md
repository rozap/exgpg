Exgpg
=====

Use gpg from elixir


## Installation

Add this to your mixfile
```elixir
 { :exgpg, "~> 0.0.3" },
```

Install [goon](https://github.com/alco/goon) and put it on your PATH.
If you can run `goon` and get a usage output, then porcelain and thereby exgpg will be able to use it. 

## Usage

#### Symmetric 

```elixir
#proc is a Porcelain.Process. The `out` key is a stream of gpg's output.
proc = Exgpg.symmetric("test string", [passphrase: "hunter2"])

# this will be a binary of the encrypted "test string"
encrypted = Enum.into(proc.out, "") 

proc = Exgpg.decrypt(encrypted, [passphrase: "hunter2"])

#put the decrypt stream into a string
Enum.into(proc.out, "") # this will be "test string"
```


#### Asymmetric
```elixir

#proc is a Porcelain.Process. The `out` key is a stream of gpg's output. this
#method allows for direct piping..
defp output(proc), do: proc.out

out = "hello world"
|> Exgpg.encrypt([{:recipient, "alice@alice.com"}, {keyring: "alice.pub"}])
|> output
|> Exgpg.decrypt([secret_keyring: "alice.sec", keyring: "alice.pub"])
|> output
|> Enum.into("")

IO.puts out # this will print "hello world"

```

#### Generate a keypair
```elixir
{:ok, proc} = Exgpg.gen_key(
      [
        key_type: "DSA",
        key_length: "1024",
        subkey_type: "ELG-E",
        subkey_length: "1024",
        name_real: "alice",
        name_email: "alice@alice.com",
        expire_date: "0",
        ctrl_pubring: "alice.pub", #pub ring will be written to alice.pub
        ctrl_secring: "alice.sec", #sec ring will be written to alice.sec
        ctrl_commit: "",
        ctrl_echo: "done"
      ]
    )

proc.status #will give the status code
proc.err #will give an error description, if one occurred
```

Options are passed directly to `gpg`, with a transformation to change the the `key_with_underscore` keylist convention in elixir to the `--key-with-dashes`. Most options should Just Work™.