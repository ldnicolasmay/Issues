defmodule Issues.GithubIssues do 

  # require Logger, only: [debug: 1, info: 1, inspect: 0]
  require Logger

  import HTTPoison, only: [get: 2]
  import Poison.Parser, only: [parse!: 1]
  
  @github_url Application.get_env(:issues, :github_url)
  @user_agent [{"User-agent", "ldnicolasmay@gmail.com"}]

  def fetch(user, project) do 
    Logger.info("Fetching #{user}'s project #{project}")

    issues_url(user, project)
    |> get(@user_agent)
    |> handle_response()
  end

  def issues_url(user, project) do 
    "#{@github_url}/repos/#{user}/#{project}/issues"
  end

  def handle_response({_, %{status_code: status_code, body: body}}) do 
    Logger.info("Got response: status_code=#{status_code}")
    Logger.debug(fn -> IO.inspect(body) end)

    {
      status_code |> check_for_error(),
      body |> parse!()
    }
  end

  defp check_for_error(200), do: :ok
  defp check_for_error(_), do: :error
end

