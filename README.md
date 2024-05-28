# Scraper

A module for scraping web pages using Hound and ChromeDriver. The Scraper module allows you to start and stop ChromeDriver sessions, load web pages, extract links, and scrape content from web pages.

## Features

- Start and stop ChromeDriver sessions.
- Load web pages and wait for them to fully load.
- Extract links based on CSS selectors.
- Scrape content from web pages with optional restrictions on site and domain.
- Customizable base URL for link filtering.

## Installation

Add `scraper` to your list of dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:scraper, github: "vectorfrog/scraper"}
  ]
end
```

Fetch the dependencies:

```sh
mix deps.get
```

## Usage

### Starting and Ending Sessions

Start a ChromeDriver session:

```elixir
Scraper.start_session()
```

End the current ChromeDriver session:

```elixir
Scraper.end_session()
```

### Loading Pages

Load a web page by URL and wait for it to fully load:

```elixir
Scraper.load_page("http://example.com")
```

### Extracting Links

Extract links from a page based on a CSS selector:

```elixir
links = Scraper.extract_links(".nav-links a")
```

### Scraping Content

Scrape a given URL, extract links using the provided CSS selector, and return the content of all linked pages:

```elixir
{links, content} = Scraper.scrape("https://example.com", base_url: "https://example.com", site_restricted: true, depth: 2)
```

#### Options

- `:link_selector` - CSS selector to extract links from a specific element.
- `:content_selector` - CSS selector to extract content from a specific element.
- `:site_restricted` - Only scrape links within the base URL.
- `:domain_restricted` - Only scrape links within the same domain.
- `:base_url` - Custom base URL for link filtering.

### Example

Here's a complete example of using the Scraper module to scrape content from a website:

```elixir
defmodule MyApp do
  def run do
    {links, content} = Scraper.scrape(
      "https://hexdocs.pm/hound/Hound.Helpers.Cookie.html#content",
      base_url: "https://hexdocs.pm/hound",
      site_restricted: true,
    )

    IO.inspect(links, label: "Links")
    IO.inspect(content, label: "Content")
  end
end

MyApp.run()
```

## Contributing

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Create a new Pull Request.

## License

This project is licensed under the MIT License.

## Acknowledgements

- [Hound](https://hexdocs.pm/hound/readme.html)
- [ChromeDriver](https://developer.chrome.com/docs/chromedriver/)

---

This README provides an overview of the Scraper module, installation instructions, usage examples, and contribution guidelines.
