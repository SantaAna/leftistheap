defmodule Heap do
  defstruct [:heap, :priority_function, :count]

  @type t :: %__MODULE__{
          heap: Heap.Node.t(),
          priority_function: prio_function,
          count: non_neg_integer
        }

  @type element :: any
  @type prio_function :: (any, any -> any)

  @moduledoc """
  Implements a leftist priroity heap as 
  described in Purely Functional Data 
  Structures by Chris Okasaki

  Insertion and popping the top off the heap run 
  in O(log n) time. Peaking at the top runs in
  O(1)

  Heap implements the enumberable and collectable protocol 
  for convenience, however if you find yourself
  using functions that work with ranges of data e.g. slice
  you should probably use a sorted list.

  """

  @doc """
  Creates a new heap with the given value at the top.
  If no function is provided in the second argument 
  <=/2 is used as a default producing a min heap.

  If a valid priority function is given an empty
  heap is created with that priority function used
  for future insertions.

  If the first value provided is a list a heap
  containing all of the list elements will be
  returned.
  """
  @spec new(element) :: t
  def new(value_list) when is_list(value_list) do
    new(value_list, &(&1 <= &2))
  end

  def new(prio_function) when is_function(prio_function) do
    if Function.info(prio_function)[:arity] == 2 do
      struct!(__MODULE__,
        heap: nil,
        priority_function: prio_function,
        count: 0
      )
    else
      raise(ArgumentError, message: "priority function must have arity of 2")
    end
  end

  def new(value) do
    new(value, &(&1 <= &2))
  end

  def new([], _), do: nil

  @doc """
  Creates a new heap with the given value at the top.
  Second argument must be a two arity function and should
  return a truthy value if the first argument is 
  higher priority than the second.

  If the first value provided is a list a heap
  containing all of the list elements will be
  returned.
  """
  @spec new(element, prio_function) :: t
  def new([hd | rst], prio_function) when is_function(prio_function) do
    if Function.info(prio_function)[:arity] == 2 do
      Enum.reduce(rst, new(hd, prio_function), fn el, acc ->
        insert(acc, el)
      end)
    else
      raise(ArgumentError, message: "priority function must have arity of 2")
    end
  end

  def new(value, prio_function) when is_function(prio_function) do
    if Function.info(prio_function)[:arity] == 2 do
      struct!(__MODULE__,
        heap: Heap.Node.new(value),
        priority_function: prio_function,
        count: 1
      )
    else
      raise(ArgumentError, message: "priority function must have arity of 2")
    end
  end

  @doc """
  Will create an empty heap with
  the default priority function <=/2
  """
  @spec new() :: t
  def new() do
    struct!(__MODULE__,
      heap: nil,
      priority_function: &(&1 <= &2),
      count: 0
    )
  end

  @doc """
  Returns the top value as determined by the priority function of the heap.
  """
  @spec top(t) :: {:ok, element} | {:error, String.t()}
  def top(%__MODULE__{count: 0}), do: {:error, "empty heap"}
  def top(%__MODULE__{heap: h}), do: {:ok, h.value}

  @doc """
  As top/1 but will raise an error for an empty heap.
  """
  @spec top!(t) :: element
  def top!(%__MODULE__{count: 0}), do: raise(ArgumentError, message: "empty heap")
  def top!(%__MODULE__{heap: h}), do: h.value

  @doc """
  Will pop the top off the heap and return a tuple
  with the top element as the first element and the
  updated tree as the second element.
  """
  @spec pop_top(t) :: {:ok, {element, t}} | {:error, String.t()}
  def pop_top(%__MODULE__{count: 0}), do: {:error, "empty heap"}

  def pop_top(%__MODULE__{heap: %{value: v, left_heap: lh, right_heap: rh}} = h) do
    h
    |> Map.put(:heap, Heap.Node.merge(lh, rh, h.priority_function))
    |> Map.update!(:count, &(&1 - 1))
    |> then(&{:ok, {v, &1}})
  end

  @doc """
  As pop_top/1 but will raise an error for a nil heap.
  """
  @spec pop_top!(t) :: {element, t}
  def pop_top!(%__MODULE__{count: 0}), do: raise(ArgumentError, message: "empty heap")

  def pop_top!(%__MODULE__{heap: %{value: v, left_heap: nil, right_heap: nil}} = h) do
    h
    |> Map.put(:heap, nil)
    |> Map.update!(:count, &(&1 - 1))
    |> then(&{v, &1})
  end

  def pop_top!(%__MODULE__{heap: %{value: v, left_heap: lh, right_heap: rh}} = h) do
    h
    |> Map.put(:heap, Heap.Node.merge(lh, rh, h.priority_function))
    |> Map.update!(:count, &(&1 - 1))
    |> then(&{v, &1})
  end

  @doc """
  Will merge the element into the heap.
  The heaps priority function is used 
  to determine heap ordering.
  """
  @spec insert(t, element) :: t
  def insert(%__MODULE__{} = h, value) do
    h
    |> Map.update!(:heap, &Heap.Node.merge(&1, Heap.Node.new(value), h.priority_function))
    |> Map.update!(:count, &(&1 + 1))
  end
end

defmodule Heap.Node do
  @moduledoc """
  Represents a node in a heap.  
  These functions should not be 
  used outside of the Heap module.
  """
  @derive {Inspect, only: [:value, :right_heap, :left_heap]}
  defstruct [:rank, :value, :left_heap, :right_heap]

  @type t :: %__MODULE__{} | nil
  def new(value) do
    struct!(__MODULE__, value: value, rank: 1, left_heap: nil, right_heap: nil)
  end

  def merge(%__MODULE__{} = h1, nil, _) do
    h1
  end

  def merge(nil, %__MODULE__{} = h2, _) do
    h2
  end

  def merge(
        %__MODULE__{value: v1, left_heap: lh1, right_heap: rh1} = h1,
        %__MODULE__{value: v2, left_heap: lh2, right_heap: rh2} = h2,
        priortiy_function
      ) do
    if priortiy_function.(v1, v2) do
      make(v1, lh1, merge(rh1, h2, priortiy_function))
    else
      make(v2, lh2, merge(rh2, h1, priortiy_function))
    end
  end

  defp rank(%__MODULE__{} = h), do: h.rank
  defp rank(nil), do: 0

  defp make(value, a, b) do
    if rank(a) >= rank(b) do
      struct!(__MODULE__,
        rank: rank(b) + 1,
        value: value,
        left_heap: a,
        right_heap: b
      )
    else
      struct!(__MODULE__,
        rank: rank(a) + 1,
        value: value,
        left_heap: b,
        right_heap: a
      )
    end
  end
end

defimpl Collectable, for: Heap do
  def into(heap) do
    collector_fun = fn
      acc, {:cont, elem} ->
        Heap.insert(acc, elem)

      acc, :done ->
        acc

      _, :halt ->
        :done
    end

    {heap, collector_fun}
  end
end

defimpl Enumerable, for: Heap do
  def reduce(_heap, {:halt, acc}, _fun), do: {:halted, acc}
  def reduce(heap, {:suspend, acc}, fun), do: {:suspend, acc, &reduce(heap, &1, fun)}
  def reduce(nil, {:cont, acc}, _fun), do: {:done, acc}

  def reduce(heap, {:cont, acc}, fun) do
    {v, nh} = Heap.pop_top!(heap)
    reduce(nh, fun.(v, acc), fun)
  end

  def count(heap), do: heap.count
  def member?(_, _), do: {:error, __MODULE__}
  def slice(_), do: {:error, __MODULE__}
end
