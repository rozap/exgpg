defmodule ExgpgTest do
  use ExUnit.Case

  test "can encrypt a string" do
    encrypted = Exgpg.encrypt("hello world", [recipient: "chrisd1891@gmail.com"])
    :timer.sleep(500)
  end
end
