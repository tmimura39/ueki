# Ueki

Ueki provides "definition of simple request methods such as `get`, `post`, etc." and "definition and handling of error exception classes for timeout error and each status code" required for HTTP Client Library.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add ueki

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install ueki

> [!CAUTION]
> `Ueki` uses faraday by default.
> However, it is possible to choose not to use faraday, so there is no dependency.
> If you want to use faraday, please install [faraday](https://github.com/lostisland/faraday).

## Usage

Simply include the Module created by Ueki in your own HTTP Client Library.

```ruby
class BookStoreClient
  include Ueki::HttpClient.new('http://example.com')

  # Class Method
  def self.delete_book(id)
    delete("/books/#{id}")
  end

  # Instance Method
  def books(limit:, offset: 0)
    get('/books', params: { limit: limit, offset: offset })
  end

  private

  def _default_headers
    h = super
    h['X-Request-Id'] = Current.request_id if Current.request_id.present?
    h
  end
end

BookStoreClient.new.post('/books', params: { title: 'Programming Ruby' })
#=> { id: 1, title: 'Programming Ruby' }

BookStoreClient.new.books(limit: 5)
#=> { books: [{ id: 1, title: 'Programming Ruby' }] }

BookStoreClient.delete_book(1)
#=> nil

BookStoreClient.get('/books/1')
#=> BookStoreClient::NotFoundError (status: 404, body: { message: 'Not Found' })
```

Exception classes are defined according to the following tree structure.
```
BookStoreClient
└── Error
    ├── RequestError
    │   ├── TimeoutError
    │   └── UnexpectedError
    └── UnsuccessfulResponseError
        ├── BadRequestError
        │   ├── UnauthorizedError
        │   ├── ForbiddenError
        │   ├── NotFoundError
        │   ├── RequestTimeoutError
        │   ├── ConflictError
        │   ├── UnprocessableEntityError
        │   └── TooManyRequestsError
        └── ServerError
```

## Why not faraday?

faraday has enough features.
However, all request error exceptions are subclasses of `Faraday::Error`.

That behavior does not allow for proper exception handling, so we repeatedly implement a process that replaces the exception.
```ruby
class BookStoreClient
  class Error < StandardError; end
  class ClientError < Error; end
  class ServerError < Error; end

  def books(limit:, offset: 0)
    connection = Faraday.new("https://example.com") do |builder|
      builder.response :raise_error
    end

    connection.get("/books")
  rescue Faraday::Error::ClientError
    raise ClientError
  end
end
```

Ueki frees us from this tedious and redundant implementation!

## How to customize

"Request Processing" is not important for Ueki.
Therefore, this part can be freely customized.

There are two ways to customize.

### Q. I enable keep alive and don't want to output logs?

A. You can use [net_http_persistent](https://github.com/lostisland/faraday-net_http_persistent) adapter by overriding `_initialize_faraday_connection`. Set up your favorite faraday middleware to match.

See [lib/ueki/http_client/default_requester.rb](https://github.com/tmimura39/ueki/blob/main/lib/ueki/http_client/default_requester.rb) for details.
```ruby
class BookStoreClient
  include Ueki::HttpClient.new('http://example.com')

  private

  def _initialize_faraday_connection(request_options)
    Faraday.new(url: self.class::ENDPOINT, headers: _default_headers, request: request_options) do |builder|
      builder.adapter :net_http_persistent, pool_size: 5 do |http|
        http.idle_timeout = 100
      end
    end
  end
end
```

### Q. How can I use faraday independent request processing across multiple Client Libraries?

A. It is recommended to create a Requester module.

A module like [lib/ueki/http_client/default_requester.rb](https://github.com/tmimura39/ueki/blob/main/lib/ueki/http_client/default_requester.rb) could be created and applied to Ueki.
In this case, you can use "automatic exception class definition" and "exception class acquisition processing according to status code ( `#pickup_unsuccessful_response_exception_class` )"

```ruby
class BookStoreClient
  include Ueki::HttpClient.new('http://example.com', requester: CustomRequester)
end
```

I am happy with my current DefaultRequester.
So this customization method is not sophisticated.
I will gladly accept any better suggestions.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tmimura39/ueki.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
