defmodule HeapTest do
  use ExUnit.Case
  doctest Heap

  describe "new/2" do
    test "will raise if prio function has the wrong arity" do
      assert_raise ArgumentError,
                   "priority function must have arity of 2",
                   fn -> Heap.new(10, &(&1 == 10)) end

      assert_raise ArgumentError, "priority function must have arity of 2", fn ->
        Heap.new(10, &(&1 + &2 + &3))
      end
    end

    test "will create a new heap if given proper arguments" do
      assert match?(%Heap{}, Heap.new(10, &(&1 + &2)))
    end

    test "will create a new heap when given a list" do
      assert match?(%Heap{}, Heap.new([1, 2, 3]))
    end
  end

  describe "top/1" do
    test "will return the correct value for non-empty heap" do
      min_heap = Heap.new([10, 9, 8])
      max_heap = Heap.new([10, 9, 8], &(&1 >= &2))
      assert Heap.top(min_heap) == {:ok, 8}
      assert Heap.top(max_heap) == {:ok, 10}
    end

    test "will recognize a empty heap" do
      assert Heap.top(%Heap{count: 0}) == {:error, "empty heap"}
    end
  end

  describe "pop_top/1" do
    test "will return the correct value for non-empty heap" do
      min_heap = Heap.new([10, 9, 8])
      max_heap = Heap.new([10, 9, 8], &(&1 >= &2))
      assert Heap.pop_top(min_heap) == {:ok, {8, Heap.new([10, 9])}}
      assert Heap.pop_top(max_heap) == {:ok, {10, Heap.new([8, 9], & &1 >= &2)}}
    end
  end
end
