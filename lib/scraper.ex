defmodule Scraper do
  use Hound.Helpers

  @moduledoc """
  A module for scraping web pages using Hound and ChromeDriver.
  """

  @doc """
  Starts a ChromeDriver session.
  """
  def start_session do
    ChromeDriver.start()
    Hound.start_session()
  end

  @doc """
  Ends the current ChromeDriver session.
  """
  def end_session do
    ChromeDriver.start()
    Hound.end_session()
  end

  @doc """
  Loads a web page by URL and waits for it to fully load.
  """
  def load_page(url, initial_wait_time \\ 1000, retry_wait_time \\ 100) do
    navigate_to(url)
    wait_for_page_load(initial_wait_time, retry_wait_time)
  end

  defp wait_for_page_load(initial_wait_time, retry_wait_time) do
    # Initial wait for any potential redirects
    :timer.sleep(initial_wait_time)

    case execute_script("return document.readyState === 'complete';") do
      true ->
        :ok

      false ->
        :timer.sleep(retry_wait_time)
        # Only use the retry wait time for subsequent retries
        wait_for_page_load(0, retry_wait_time)
    end
  end

  @doc """
  Extracts links from a page based on the provided CSS selector.
  """
  def extract_links(nil), do: extract_links("")

  def extract_links(css_selector) do
    css_selector =
      case ends_with_space_a?(css_selector) do
        true -> css_selector
        false -> css_selector <> " a"
      end

    links = find_all_elements(:css, css_selector)

    links
    |> Enum.map(&attribute_value(&1, "href"))
    |> IO.inspect(label: "links")
  end

  defp ends_with_space_a?(string) do
    case String.split_at(string, -2) do
      {_, " a"} -> true
      _ -> false
    end
  end

  defp strip_anchor(link) do
    case String.split(link, "#") do
      [base_url | _] -> base_url
      _ -> link
    end
  end

  @doc """
  Scrapes a given URL, extracts links using the provided CSS selector,
  and returns the content of all linked pages.

  Options:
    * `:link_selector` - CSS selector to extract links from a specific element.
    * `:content_selector` - CSS selector to extract content from a specific element.
    * `:site_restricted` - only scrape links within the base URL.
    * `:domain_restricted` - only scrape links within the same domain.
    * `:base_url` - custom base URL for link filtering.
    * `:initial_wait_time` - initial wait time for the page to load (default is 1000 ms).
    * `:retry_wait_time` - retry wait time for the page to load (default is 100 ms).
  """
  def scrape(url, opts \\ []) do
    Scraper.start_session()

    try do
      initial_wait_time = Keyword.get(opts, :initial_wait_time, 1000)
      retry_wait_time = Keyword.get(opts, :retry_wait_time, 100)

      load_page(url, initial_wait_time, retry_wait_time)
      base_url = Keyword.get(opts, :base_url, get_base_url(url))
      domain = URI.parse(base_url).host

      link_selector = Keyword.get(opts, :link_selector, "")
      content_selector = Keyword.get(opts, :content_selector, nil)

      links =
        extract_links(link_selector)
        |> Enum.map(&to_absolute_url(&1, base_url))
        |> Enum.uniq()
        |> Enum.filter(&filter_link(&1, base_url, domain, opts))

      content =
        Enum.map(
          links,
          &fetch_page_content(&1, content_selector, initial_wait_time, retry_wait_time)
        )

      {links, content}
    rescue
      error -> IO.inspect(error, label: "Error")
    after
      Scraper.end_session()
    end
  end

  defp filter_link(link, base_url, domain, opts) do
    cond do
      Keyword.get(opts, :site_restricted, false) and not String.starts_with?(link, base_url) ->
        false

      Keyword.get(opts, :domain_restricted, false) and URI.parse(link).host != domain ->
        false

      true ->
        true
    end
  end

  @doc """
  Fetches the content of a web page given its URL.
  If a CSS selector is provided, returns the HTML within that element, otherwise returns the entire page's HTML.
  """
  def fetch_page_content(link, selector \\ nil, initial_wait_time, retry_wait_time) do
    Status.info("loading: #{link}")
    load_page(link, initial_wait_time, retry_wait_time)

    script =
      if selector do
        "return document.querySelector(arguments[0])?.outerHTML || '';"
      else
        "return document.documentElement.outerHTML;"
      end

    execute_script(script, [selector])
  end

  defp get_base_url(url) do
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}"
  end

  defp to_absolute_url(link, base_url) do
    link = strip_anchor(link)

    case URI.parse(link) do
      %URI{scheme: nil} -> base_url <> link
      %URI{} = uri -> URI.to_string(uri)
    end
  end
end
