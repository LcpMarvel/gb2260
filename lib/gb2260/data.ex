defmodule GB2260.Data do
  @moduledoc """
  The Elixir implementation for looking up the Chinese administrative divisions.
  """

  @data_path Path.join(__DIR__, "../../data")

  {:ok, files} = File.ls(@data_path)

  paths = files
            |> Enum.filter(fn(file_name) -> String.match?(file_name, ~r/.*\.tsv/) end)
            |> Enum.map(fn(file_name) -> @data_path <> "/" <> file_name end)

  revisions = "#{@data_path}/revisions.json"
              |> File.read!
              |> Poison.Parser.parse!
              |> Map.fetch!("revisions")
              |> Enum.map(
                fn(revision) ->
                  revision
                    |> String.slice(0..3)
                    |> String.to_integer
                end
              )

  @doc """
  Return all revisions
  """
  @spec revisions() :: [non_neg_integer]
  def revisions do
    unquote(revisions)
  end

  @doc """
  Return last revision
  """
  @spec last_revision() :: non_neg_integer
  def last_revision do
    unquote(revisions |> Enum.sort |> List.last)
  end

  @spec data(non_neg_integer) :: map
  def data(revision) do
    fetch_data(revision)
  end

  @spec fetch_data(non_neg_integer) :: map
  defp fetch_data(revision) do
    file_path = file_paths
                |> Enum.find(fn(path) -> Regex.match?(~r/#{revision}/, path) end)

    File.stream!(file_path)
      |> Enum.reduce(
        %{},
        fn(line, map) ->
          case line do
            "Source\tRevision\tCode\tName" ->
              map
            _ ->
              [_source, _revision, code, name] = String.split(line, "\t")

              Dict.put(map, code, String.strip(name))
          end
        end
      )
  end

  @doc """
  Return region name
  """
  @spec fetch(String.t, non_neg_integer) :: String.t | nil
  def fetch(code, revision) do
    data(revision) |> Dict.get(code)
  end

  @spec file_paths() :: [String.t]
  def file_paths do
    unquote(paths)
  end

  @doc false
  @spec is_province?(String.t) :: boolean
  def is_province?(code) do
    "#{province_prefix(code)}0000" == code
  end

  @doc false
  @spec is_prefecture?(String.t) :: boolean
  def is_prefecture?(code) do
    !is_province?(code) && "#{prefecture_prefix(code)}00" == code
  end

  @doc false
  @spec is_county?(String.t) :: boolean
  def is_county?(code) do
    !is_province?(code) && "#{prefecture_prefix(code)}00" != code
  end

  @doc false
  @spec province_prefix(String.t) :: String.t
  def province_prefix(code) do
    String.slice(code, 0..1)
  end

  @doc false
  @spec prefecture_prefix(String.t) :: String.t
  def prefecture_prefix(code) do
    String.slice(code, 0..3)
  end

  @doc false
  @spec province_code(Division.Division.t) :: String.t
  def province_code(division) do
    province_prefix(division.code) <> "0000"
  end

  @doc false
  @spec prefecture_code(Division.Division.t) :: String.t
  def prefecture_code(division) do
    prefecture_prefix(division.code) <> "00"
  end
end
