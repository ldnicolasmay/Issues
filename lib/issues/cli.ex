defmodule Issues.CLI do
  @default_count 4

  @moduledoc """
  Handle the command line parsing and the dispatch to
  the various functions that end up generating a
  table of the last _n_ issues in a github project
  """

  def run(argv) do
    # parse_args(argv)
    argv
    |> parse_args()
    |> process()
  end

  @doc """
  `argv` can be -h or --help, with returns :help.

  Otherwise it is a github user name, project name, and (optionally) the number of entries to format

  Return a tuple of `{user, project, count}`, or `:help` if help was given.
  """

  # def parse_args(argv) do 
  #   parse = OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])
  #   case parse do 
  #     {[help: true], _, _} -> :help
  #     {_, [user, project, count], _} -> {user, project, String.to_integer(count)}
  #     {_, [user, project], _} -> {user, project, @default_count}
  #     _ -> :help 
  #   end
  # end

  def parse_args(argv) do
    OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])
    |> elem(1)
    |> args_to_internal_representation()
  end

  def args_to_internal_representation([user, project, count]) do
    {user, project, String.to_integer(count)}
  end

  def args_to_internal_representation([user, project]) do
    {user, project, @default_count}
  end

  # bad arg or --help
  def args_to_internal_representation(_) do
    :help
  end

  def process(:help) do
    IO.puts("""
    usage: issues <user> <project> [count | #{@default_count}]"
    """)

    System.halt(0)
  end

  # def process({user, project, _count}) do 
  #   Issues.GithubIssues.fetch(user, project)
  # end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response()
    |> sort_into_descending_order()
    |> last(count)
    |> get_issues_target_fields()
    |> extract_max_field_widths({0, 0, 0})
    |> print_header()
    |> print_issues()
  end

  def decode_response({:ok, body}), do: body

  def decode_response({:error, error}) do
    IO.puts("Error fetching from Github: #{error["message"]}")
    System.halt(2)
  end

  def sort_into_descending_order(issues_list) do
    issues_list
    |> Enum.sort(fn i1, i2 -> i1["created_at"] >= i2["created_at"] end)
  end

  def last(issues_list, count) do
    issues_list
    |> Enum.take(count)
    |> Enum.reverse()
  end

  def get_issues_target_fields(issues_list) do 
    issues_list
    |> Enum.map(&Map.take(&1, ["id", "created_at", "title"]))
    # |> Enum.map(&get_issue_target_fields/1)
  end

  # def get_issue_target_fields(
  #   %{"id" => id, "created_at" => created_at, "title" => title}
  # ) do 
  #   %{"id" => id, "created_at" => created_at, "title" => title}
  # end
  
  def extract_max_field_widths(issues_list, lens) do 
    extract_max_field_widths(issues_list, issues_list, lens)
  end

  def extract_max_field_widths(issues_list, [], max_lens) do 
    %{issues_list: issues_list, max_lens: max_lens}
  end

  def extract_max_field_widths(
    issues_list,
    [head | tail],
    {max_id, max_created_at, max_title}
  ) do 
    with id_len = Integer.digits(head["id"]) |> length(),
         created_ad_len = String.length(head["created_at"]),
         title_len = String.length(head["title"]),
         longer_id_len = max(max_id, id_len),
         longer_created_at_len = max(max_created_at, created_ad_len),
         longer_title_len = max(max_title, title_len)
    do 
      extract_max_field_widths(
        issues_list, 
        tail, 
        {longer_id_len, longer_created_at_len, longer_title_len}
      )
    end
  end

  def print_header(
    issues_lengths = %{
      issues_list: _, 
      max_lens: {max_id_len, max_created_at_len, max_title_len}
    }
  ) do 
    with padded_id = String.pad_trailing("#", max_id_len),
         padded_created_at = String.pad_trailing("created_at", max_created_at_len),
         padded_title = String.pad_trailing("title", max_title_len),
         padded_id_dash = String.pad_trailing("", max_id_len, "-"),
         padded_created_at_dash = String.pad_trailing("", max_created_at_len, "-"),
         padded_title_dash = String.pad_trailing("", max_title_len, "-")
    do 
      IO.puts(" #{padded_id} | #{padded_created_at} | #{padded_title}")
      IO.puts("-#{padded_id_dash}-+-#{padded_created_at_dash}-+-#{padded_title_dash}-")
      issues_lengths
    end
  end

  def print_issues(%{issues_list: issues_list, max_lens: max_lens}) do
    issues_list
    |> Enum.each(&print_issue_row(&1, max_lens))
  end

  def print_issue_row(issue, {max_id_len, max_created_at_len, max_title_len}) do 
    with padded_id = Integer.to_string(issue["id"]) 
                     |> String.pad_leading(max_id_len),
         padded_created_at = String.pad_leading(issue["created_at"], max_created_at_len),
         padded_title = String.pad_trailing(issue["title"], max_title_len)
    do
      IO.puts(" #{padded_id} | #{padded_created_at} | #{padded_title}")
    end
  end

end
