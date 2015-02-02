Exgpg
=====

Use gpg from elixir


## Installation

Add this to your mixfile
```elixir
 { :exgpg, "~> 0.0.1" },
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


Enum.into(proc.out, "") # this will be "test string"
```


#### Asymmetric
```elixir

keyrings = [
  secret_keyring: "/path/to/keyring.sec",
  keyring: "/path/to/keyring.pub"
]

out = "hello world"
|> Exgpg.encrypt([{:recipient, "test@test.com"} | keyrings])
|> Enum.into("")
|> Exgpg.decrypt(keyrings)
|> Enum.into("")

out # this will be "hello world"

```

Options are passed directly to `gpg`, with a transformation to change the the `key_with_underscore` keylist convention in elixir to the `--key-with-dashes`. Most options should Just Work™.