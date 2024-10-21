# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Ueki::HttpClient do
  let!(:dummy_client_class) do
    Class.new.include(described_class.new(endpoint)).tap do |klass|
      allow(klass).to receive(:name).and_return("DummyClient")
    end
  end
  let!(:endpoint) { "https://example.com" }

  it "ENDPOINT to be defined" do
    expect(dummy_client_class::ENDPOINT).to eq endpoint
  end

  describe "ExceptionClassBuilder" do
    it "Exceptions to be defined" do
      constants = dummy_client_class.constants
      expect(constants).to match_array %i[
        ENDPOINT
        Error
        RequestError
        TimeoutError
        UnexpectedError
        UnsuccessfulResponseError
        BadRequestError
        UnauthorizedError
        ForbiddenError
        NotFoundError
        RequestTimeoutError
        ConflictError
        UnprocessableEntityError
        TooManyRequestsError
        ServerError
      ]

      # Error
      # ├── RequestError
      # │   ├── TimeoutError
      # │   └── UnexpectedError
      # └── UnsuccessfulResponseError
      #     ├── BadRequestError
      #     │   ├── UnauthorizedError
      #     │   ├── ForbiddenError
      #     │   ├── NotFoundError
      #     │   ├── RequestTimeoutError
      #     │   ├── ConflictError
      #     │   ├── UnprocessableEntityError
      #     │   └── TooManyRequestsError
      #     └── ServerError
      expect(dummy_client_class::RequestError < dummy_client_class::Error).to be true
      expect(dummy_client_class::TimeoutError < dummy_client_class::RequestError).to be true
      expect(dummy_client_class::UnexpectedError < dummy_client_class::RequestError).to be true
      expect(dummy_client_class::UnsuccessfulResponseError < dummy_client_class::Error).to be true
      expect(dummy_client_class::BadRequestError < dummy_client_class::UnsuccessfulResponseError).to be true
      expect(dummy_client_class::UnauthorizedError < dummy_client_class::BadRequestError).to be true
      expect(dummy_client_class::ForbiddenError < dummy_client_class::BadRequestError).to be true
      expect(dummy_client_class::NotFoundError < dummy_client_class::BadRequestError).to be true
      expect(dummy_client_class::RequestTimeoutError < dummy_client_class::BadRequestError).to be true
      expect(dummy_client_class::ConflictError < dummy_client_class::BadRequestError).to be true
      expect(dummy_client_class::UnprocessableEntityError < dummy_client_class::BadRequestError).to be true
      expect(dummy_client_class::TooManyRequestsError < dummy_client_class::BadRequestError).to be true
      expect(dummy_client_class::ServerError < dummy_client_class::UnsuccessfulResponseError).to be true
    end
  end

  describe "RequesterShorthand" do
    describe ".get" do
      it "can do http request" do
        stub = stub_request(:get, "https://example.com/users")
               .with(query: { page: 10, per: 1 })
               .with(headers: { "User-Agent" => "DummyClient" })
               .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

        response = dummy_client_class.get("/users", params: { page: 10, per: 1 })
        expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
        expect(stub).to have_been_requested
      end
    end

    describe ".post" do
      it "can do http request" do
        stub = stub_request(:post, "https://example.com/users")
               .with(body: { name: "tarou" })
               .with(headers: { "User-Agent" => "DummyClient" })
               .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

        response = dummy_client_class.post("/users", params: { name: "tarou" })
        expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
        expect(stub).to have_been_requested
      end
    end

    describe ".put" do
      it "can do http request" do
        stub = stub_request(:put, "https://example.com/users")
               .with(body: { name: "tarou" })
               .with(headers: { "User-Agent" => "DummyClient" })
               .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

        response = dummy_client_class.put("/users", params: { name: "tarou" })
        expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
        expect(stub).to have_been_requested
      end
    end

    describe ".patch" do
      it "can do http request" do
        stub = stub_request(:patch, "https://example.com/users")
               .with(body: { name: "tarou" })
               .with(headers: { "User-Agent" => "DummyClient" })
               .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

        response = dummy_client_class.patch("/users", params: { name: "tarou" })
        expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
        expect(stub).to have_been_requested
      end
    end

    describe ".delete" do
      it "can do http request" do
        stub = stub_request(:delete, "https://example.com/users")
               .with(query: { page: 10, per: 1 })
               .with(headers: { "User-Agent" => "DummyClient" })
               .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

        response = dummy_client_class.delete("/users", params: { page: 10, per: 1 })
        expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
        expect(stub).to have_been_requested
      end
    end
  end

  describe "Requester" do
    describe "#get" do
      describe "RequestParameter" do
        it "reflected in the query string" do
          stub = stub_request(:get, "https://example.com/users")
                 .with(query: { page: 10, per: 1 })
                 .to_return(status: 200)

          dummy_client_class.new.get("/users", params: { page: 10, per: 1 })
          expect(stub).to have_been_requested
        end
      end

      describe "RequestHeader" do
        describe "User-Agent" do
          it "Class name to be set (default)" do
            stub = stub_request(:get, "https://example.com/users")
                   .with(headers: { "User-Agent" => "DummyClient" })

            dummy_client_class.new.get("/users")
            expect(stub).to have_been_requested
          end
        end
      end

      describe "ResponseBody" do
        context "with ResponseBody" do
          it "parsed ResponseBody to be returned" do
            stub = stub_request(:get, "https://example.com/users")
                   .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

            response = dummy_client_class.new.get("/users")
            expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
            expect(stub).to have_been_requested
          end
        end

        context "without ResponseBody" do
          it "nil to be returned" do
            stub = stub_request(:get, "https://example.com/users")
                   .to_return(status: 204)

            response = dummy_client_class.new.get("/users")
            expect(response).to be_nil
            expect(stub).to have_been_requested
          end
        end
      end

      describe "RequestError" do
        context "when timeout" do
          it "raise TimeoutError" do
            stub = stub_request(:get, "https://example.com/users")
                   .to_raise(Faraday::TimeoutError)

            expect { dummy_client_class.new.get("/users") }
              .to raise_error(dummy_client_class::TimeoutError)
            expect(stub).to have_been_requested
          end
        end

        context "when unexpected request error" do
          it "raise UnexpectedError" do
            stub = stub_request(:get, "https://example.com/users")
                   .to_raise

            expect { dummy_client_class.new.get("/users") }
              .to raise_error(dummy_client_class::UnexpectedError)
            expect(stub).to have_been_requested
          end
        end
      end

      describe "ResponseError" do
        describe "ResponseBody" do
          context "with ResponseBody" do
            it "raise exception object with parsed response" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 400, body: { message: "Bad Request" }.to_json)

              expected_exception = an_instance_of(dummy_client_class::BadRequestError)
                                   .and(have_attributes(status: 400, body: { message: "Bad Request" }))
              expect { dummy_client_class.new.get("/users") }
                .to raise_error(expected_exception)
              expect(stub).to have_been_requested
            end
          end

          context "without ResponseBody" do
            it "raise exception object with nil body" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 400)

              expected_exception = an_instance_of(dummy_client_class::BadRequestError)
                                   .and(have_attributes(status: 400, body: nil))
              expect { dummy_client_class.new.get("/users") }
                .to raise_error(expected_exception)
              expect(stub).to have_been_requested
            end
          end
        end

        describe "exception dispatch" do
          context "when 400" do
            it "raise BadRequestError" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 400)

              expect { dummy_client_class.new.get("/users") }
                .to raise_error(dummy_client_class::BadRequestError)
              expect(stub).to have_been_requested
            end
          end

          context "when 401" do
            it "raise UnauthorizedError" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 401)

              expect { dummy_client_class.new.get("/users") }
                .to raise_error(dummy_client_class::UnauthorizedError)
              expect(stub).to have_been_requested
            end
          end

          context "when 403" do
            it "raise ForbiddenError" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 403)

              expect { dummy_client_class.new.get("/users") }
                .to raise_error(dummy_client_class::ForbiddenError)
              expect(stub).to have_been_requested
            end
          end

          context "when 404" do
            it "raise NotFoundError" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 404)

              expect { dummy_client_class.new.get("/users") }
                .to raise_error(dummy_client_class::NotFoundError)
              expect(stub).to have_been_requested
            end
          end

          context "when 408" do
            it "raise RequestTimeoutError" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 408)

              expect { dummy_client_class.new.get("/users") }
                .to raise_error(dummy_client_class::RequestTimeoutError)
              expect(stub).to have_been_requested
            end
          end

          context "when 409" do
            it "raise ConflictError" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 409)

              expect { dummy_client_class.new.get("/users") }
                .to raise_error(dummy_client_class::ConflictError)
              expect(stub).to have_been_requested
            end
          end

          context "when 422" do
            it "raise UnprocessableEntityError" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 422)

              expect { dummy_client_class.new.get("/users") }
                .to raise_error(dummy_client_class::UnprocessableEntityError)
              expect(stub).to have_been_requested
            end
          end

          context "when 429" do
            it "raise TooManyRequestsError" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 429)

              expect { dummy_client_class.new.get("/users") }
                .to raise_error(dummy_client_class::TooManyRequestsError)
              expect(stub).to have_been_requested
            end
          end

          context "when 500" do
            it "raise ServerError" do
              stub = stub_request(:get, "https://example.com/users")
                     .to_return(status: 500)

              expect { dummy_client_class.new.get("/users") }
                .to raise_error(dummy_client_class::ServerError)
              expect(stub).to have_been_requested
            end
          end
        end
      end
    end

    describe "#post" do
      describe "RequestParameter" do
        it "reflected in the request body" do
          stub = stub_request(:post, "https://example.com/users")
                 .with(body: { name: "tarou" })
                 .to_return(status: 200)

          dummy_client_class.new.post("/users", params: { name: "tarou" })
          expect(stub).to have_been_requested
        end
      end

      describe "RequestHeader" do
        describe "User-Agent" do
          it "Class name to be set (default)" do
            stub = stub_request(:post, "https://example.com/users")
                   .with(headers: { "User-Agent" => "DummyClient" })

            dummy_client_class.new.post("/users")
            expect(stub).to have_been_requested
          end
        end

        describe "Content-Type" do
          context "with RequestBody" do
            context "when 'Content-Type' unspecified" do
              it "application/json to be set (default)" do
                stub = stub_request(:post, "https://example.com/users")
                       .with(headers: { "User-Agent" => "DummyClient", "Content-Type" => "application/json" })

                dummy_client_class.new.post("/users", params: { name: "tarou" })
                expect(stub).to have_been_requested
              end
            end

            context "when 'Content-Type (string key)' specified" do
              it "specified 'Content-Type' to be set" do
                stub = stub_request(:post, "https://example.com/users")
                       .with(headers: { "User-Agent" => "DummyClient", "Content-Type" => "application/x-www-form-urlencoded" })

                dummy_client_class.new.post("/users", params: { name: "tarou" }, headers: { "Content-Type" => "application/x-www-form-urlencoded" })
                expect(stub).to have_been_requested
              end
            end

            context "when 'Content-Type (symbol key)' specified" do
              it "specified 'Content-Type' to be set" do
                stub = stub_request(:post, "https://example.com/users")
                       .with(headers: { "User-Agent" => "DummyClient", "Content-Type" => "application/x-www-form-urlencoded" })

                dummy_client_class.new.post("/users", params: { name: "tarou" }, headers: { "Content-Type": "application/x-www-form-urlencoded" })
                expect(stub).to have_been_requested
              end
            end
          end

          context "without RequestBody" do
            it "application/json not to be set (default)" do
              stub = stub_request(:post, "https://example.com/users")
                     .with(headers: { "User-Agent" => "DummyClient" })

              dummy_client_class.new.post("/users")
              expect(stub).to have_been_requested
            end
          end
        end
      end

      describe "ResponseBody" do
        context "with ResponseBody" do
          it "parsed ResponseBody to be returned" do
            stub = stub_request(:post, "https://example.com/users")
                   .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

            response = dummy_client_class.new.post("/users")
            expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
            expect(stub).to have_been_requested
          end
        end

        context "without ResponseBody" do
          it "nil to be returned" do
            stub = stub_request(:post, "https://example.com/users")
                   .to_return(status: 204)

            response = dummy_client_class.new.post("/users")
            expect(response).to be_nil
            expect(stub).to have_been_requested
          end
        end
      end

      describe "RequestError" do
        context "when timeout" do
          it "raise TimeoutError" do
            stub = stub_request(:post, "https://example.com/users")
                   .to_raise(Faraday::TimeoutError)

            expect { dummy_client_class.new.post("/users") }
              .to raise_error(dummy_client_class::TimeoutError)
            expect(stub).to have_been_requested
          end
        end

        context "when unexpected request error" do
          it "raise UnexpectedError" do
            stub = stub_request(:post, "https://example.com/users")
                   .to_raise

            expect { dummy_client_class.new.post("/users") }
              .to raise_error(dummy_client_class::UnexpectedError)
            expect(stub).to have_been_requested
          end
        end
      end

      describe "ResponseError" do
        describe "ResponseBody" do
          context "with ResponseBody" do
            it "raise exception object with parsed response" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 400, body: { message: "Bad Request" }.to_json)

              expected_exception = an_instance_of(dummy_client_class::BadRequestError)
                                   .and(have_attributes(status: 400, body: { message: "Bad Request" }))
              expect { dummy_client_class.new.post("/users") }
                .to raise_error(expected_exception)
              expect(stub).to have_been_requested
            end
          end

          context "without ResponseBody" do
            it "raise exception object with nil body" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 400)

              expected_exception = an_instance_of(dummy_client_class::BadRequestError)
                                   .and(have_attributes(status: 400, body: nil))
              expect { dummy_client_class.new.post("/users") }
                .to raise_error(expected_exception)
              expect(stub).to have_been_requested
            end
          end
        end

        describe "exception dispatch" do
          context "when 400" do
            it "raise BadRequestError" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 400)

              expect { dummy_client_class.new.post("/users") }
                .to raise_error(dummy_client_class::BadRequestError)
              expect(stub).to have_been_requested
            end
          end

          context "when 401" do
            it "raise UnauthorizedError" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 401)

              expect { dummy_client_class.new.post("/users") }
                .to raise_error(dummy_client_class::UnauthorizedError)
              expect(stub).to have_been_requested
            end
          end

          context "when 403" do
            it "raise ForbiddenError" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 403)

              expect { dummy_client_class.new.post("/users") }
                .to raise_error(dummy_client_class::ForbiddenError)
              expect(stub).to have_been_requested
            end
          end

          context "when 404" do
            it "raise NotFoundError" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 404)

              expect { dummy_client_class.new.post("/users") }
                .to raise_error(dummy_client_class::NotFoundError)
              expect(stub).to have_been_requested
            end
          end

          context "when 408" do
            it "raise RequestTimeoutError" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 408)

              expect { dummy_client_class.new.post("/users") }
                .to raise_error(dummy_client_class::RequestTimeoutError)
              expect(stub).to have_been_requested
            end
          end

          context "when 409" do
            it "raise ConflictError" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 409)

              expect { dummy_client_class.new.post("/users") }
                .to raise_error(dummy_client_class::ConflictError)
              expect(stub).to have_been_requested
            end
          end

          context "when 422" do
            it "raise UnprocessableEntityError" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 422)

              expect { dummy_client_class.new.post("/users") }
                .to raise_error(dummy_client_class::UnprocessableEntityError)
              expect(stub).to have_been_requested
            end
          end

          context "when 429" do
            it "raise TooManyRequestsError" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 429)

              expect { dummy_client_class.new.post("/users") }
                .to raise_error(dummy_client_class::TooManyRequestsError)
              expect(stub).to have_been_requested
            end
          end

          context "when 500" do
            it "raise ServerError" do
              stub = stub_request(:post, "https://example.com/users")
                     .to_return(status: 500)

              expect { dummy_client_class.new.post("/users") }
                .to raise_error(dummy_client_class::ServerError)
              expect(stub).to have_been_requested
            end
          end
        end
      end
    end

    describe "#put" do
      describe "RequestParameter" do
        it "reflected in the request body" do
          stub = stub_request(:put, "https://example.com/users")
                 .with(body: { name: "tarou" })
                 .to_return(status: 200)

          dummy_client_class.new.put("/users", params: { name: "tarou" })
          expect(stub).to have_been_requested
        end
      end

      describe "RequestHeader" do
        describe "User-Agent" do
          it "Class name to be set (default)" do
            stub = stub_request(:put, "https://example.com/users")
                   .with(headers: { "User-Agent" => "DummyClient" })

            dummy_client_class.new.put("/users")
            expect(stub).to have_been_requested
          end
        end

        describe "Content-Type" do
          context "with RequestBody" do
            context "when 'Content-Type' unspecified" do
              it "application/json to be set (default)" do
                stub = stub_request(:put, "https://example.com/users")
                       .with(headers: { "User-Agent" => "DummyClient", "Content-Type" => "application/json" })

                dummy_client_class.new.put("/users", params: { name: "tarou" })
                expect(stub).to have_been_requested
              end
            end

            context "when 'Content-Type (string key)' specified" do
              it "specified 'Content-Type' to be set" do
                stub = stub_request(:put, "https://example.com/users")
                       .with(headers: { "User-Agent" => "DummyClient", "Content-Type" => "application/x-www-form-urlencoded" })

                dummy_client_class.new.put("/users", params: { name: "tarou" }, headers: { "Content-Type" => "application/x-www-form-urlencoded" })
                expect(stub).to have_been_requested
              end
            end

            context "when 'Content-Type (symbol key)' specified" do
              it "specified 'Content-Type' to be set" do
                stub = stub_request(:put, "https://example.com/users")
                       .with(headers: { "User-Agent" => "DummyClient", "Content-Type" => "application/x-www-form-urlencoded" })

                dummy_client_class.new.put("/users", params: { name: "tarou" }, headers: { "Content-Type": "application/x-www-form-urlencoded" })
                expect(stub).to have_been_requested
              end
            end
          end

          context "without RequestBody" do
            it "application/json not to be set (default)" do
              stub = stub_request(:put, "https://example.com/users")
                     .with(headers: { "User-Agent" => "DummyClient" })

              dummy_client_class.new.put("/users")
              expect(stub).to have_been_requested
            end
          end
        end
      end

      describe "ResponseBody" do
        context "with ResponseBody" do
          it "parsed ResponseBody to be returned" do
            stub = stub_request(:put, "https://example.com/users")
                   .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

            response = dummy_client_class.new.put("/users")
            expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
            expect(stub).to have_been_requested
          end
        end

        context "without ResponseBody" do
          it "nil to be returned" do
            stub = stub_request(:put, "https://example.com/users")
                   .to_return(status: 204)

            response = dummy_client_class.new.put("/users")
            expect(response).to be_nil
            expect(stub).to have_been_requested
          end
        end
      end

      describe "RequestError" do
        context "when timeout" do
          it "raise TimeoutError" do
            stub = stub_request(:put, "https://example.com/users")
                   .to_raise(Faraday::TimeoutError)

            expect { dummy_client_class.new.put("/users") }
              .to raise_error(dummy_client_class::TimeoutError)
            expect(stub).to have_been_requested
          end
        end

        context "when unexpected request error" do
          it "raise UnexpectedError" do
            stub = stub_request(:put, "https://example.com/users")
                   .to_raise

            expect { dummy_client_class.new.put("/users") }
              .to raise_error(dummy_client_class::UnexpectedError)
            expect(stub).to have_been_requested
          end
        end
      end

      describe "ResponseError" do
        describe "ResponseBody" do
          context "with ResponseBody" do
            it "raise exception object with parsed response" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 400, body: { message: "Bad Request" }.to_json)

              expected_exception = an_instance_of(dummy_client_class::BadRequestError)
                                   .and(have_attributes(status: 400, body: { message: "Bad Request" }))
              expect { dummy_client_class.new.put("/users") }
                .to raise_error(expected_exception)
              expect(stub).to have_been_requested
            end
          end

          context "without ResponseBody" do
            it "raise exception object with nil body" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 400)

              expected_exception = an_instance_of(dummy_client_class::BadRequestError)
                                   .and(have_attributes(status: 400, body: nil))
              expect { dummy_client_class.new.put("/users") }
                .to raise_error(expected_exception)
              expect(stub).to have_been_requested
            end
          end
        end

        describe "exception dispatch" do
          context "when 400" do
            it "raise BadRequestError" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 400)

              expect { dummy_client_class.new.put("/users") }
                .to raise_error(dummy_client_class::BadRequestError)
              expect(stub).to have_been_requested
            end
          end

          context "when 401" do
            it "raise UnauthorizedError" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 401)

              expect { dummy_client_class.new.put("/users") }
                .to raise_error(dummy_client_class::UnauthorizedError)
              expect(stub).to have_been_requested
            end
          end

          context "when 403" do
            it "raise ForbiddenError" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 403)

              expect { dummy_client_class.new.put("/users") }
                .to raise_error(dummy_client_class::ForbiddenError)
              expect(stub).to have_been_requested
            end
          end

          context "when 404" do
            it "raise NotFoundError" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 404)

              expect { dummy_client_class.new.put("/users") }
                .to raise_error(dummy_client_class::NotFoundError)
              expect(stub).to have_been_requested
            end
          end

          context "when 408" do
            it "raise RequestTimeoutError" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 408)

              expect { dummy_client_class.new.put("/users") }
                .to raise_error(dummy_client_class::RequestTimeoutError)
              expect(stub).to have_been_requested
            end
          end

          context "when 409" do
            it "raise ConflictError" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 409)

              expect { dummy_client_class.new.put("/users") }
                .to raise_error(dummy_client_class::ConflictError)
              expect(stub).to have_been_requested
            end
          end

          context "when 422" do
            it "raise UnprocessableEntityError" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 422)

              expect { dummy_client_class.new.put("/users") }
                .to raise_error(dummy_client_class::UnprocessableEntityError)
              expect(stub).to have_been_requested
            end
          end

          context "when 429" do
            it "raise TooManyRequestsError" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 429)

              expect { dummy_client_class.new.put("/users") }
                .to raise_error(dummy_client_class::TooManyRequestsError)
              expect(stub).to have_been_requested
            end
          end

          context "when 500" do
            it "raise ServerError" do
              stub = stub_request(:put, "https://example.com/users")
                     .to_return(status: 500)

              expect { dummy_client_class.new.put("/users") }
                .to raise_error(dummy_client_class::ServerError)
              expect(stub).to have_been_requested
            end
          end
        end
      end
    end

    describe "#patch" do
      describe "RequestParameter" do
        it "reflected in the request body" do
          stub = stub_request(:patch, "https://example.com/users")
                 .with(body: { name: "tarou" })
                 .to_return(status: 200)

          dummy_client_class.new.patch("/users", params: { name: "tarou" })
          expect(stub).to have_been_requested
        end
      end

      describe "RequestHeader" do
        describe "User-Agent" do
          it "Class name to be set (default)" do
            stub = stub_request(:patch, "https://example.com/users")
                   .with(headers: { "User-Agent" => "DummyClient" })

            dummy_client_class.new.patch("/users")
            expect(stub).to have_been_requested
          end
        end

        describe "Content-Type" do
          context "with RequestBody" do
            context "when 'Content-Type' unspecified" do
              it "application/json to be set (default)" do
                stub = stub_request(:patch, "https://example.com/users")
                       .with(headers: { "User-Agent" => "DummyClient", "Content-Type" => "application/json" })

                dummy_client_class.new.patch("/users", params: { name: "tarou" })
                expect(stub).to have_been_requested
              end
            end

            context "when 'Content-Type (string key)' specified" do
              it "specified 'Content-Type' to be set" do
                stub = stub_request(:patch, "https://example.com/users")
                       .with(headers: { "User-Agent" => "DummyClient", "Content-Type" => "application/x-www-form-urlencoded" })

                dummy_client_class.new.patch("/users", params: { name: "tarou" }, headers: { "Content-Type" => "application/x-www-form-urlencoded" })
                expect(stub).to have_been_requested
              end
            end

            context "when 'Content-Type (symbol key)' specified" do
              it "specified 'Content-Type' to be set" do
                stub = stub_request(:patch, "https://example.com/users")
                       .with(headers: { "User-Agent" => "DummyClient", "Content-Type" => "application/x-www-form-urlencoded" })

                dummy_client_class.new.patch("/users", params: { name: "tarou" }, headers: { "Content-Type": "application/x-www-form-urlencoded" })
                expect(stub).to have_been_requested
              end
            end
          end

          context "without RequestBody" do
            it "application/json not to be set (default)" do
              stub = stub_request(:patch, "https://example.com/users")
                     .with(headers: { "User-Agent" => "DummyClient" })

              dummy_client_class.new.patch("/users")
              expect(stub).to have_been_requested
            end
          end
        end
      end

      describe "ResponseBody" do
        context "with ResponseBody" do
          it "parsed ResponseBody to be returned" do
            stub = stub_request(:patch, "https://example.com/users")
                   .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

            response = dummy_client_class.new.patch("/users")
            expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
            expect(stub).to have_been_requested
          end
        end

        context "without ResponseBody" do
          it "nil to be returned" do
            stub = stub_request(:patch, "https://example.com/users")
                   .to_return(status: 204)

            response = dummy_client_class.new.patch("/users")
            expect(response).to be_nil
            expect(stub).to have_been_requested
          end
        end
      end

      describe "RequestError" do
        context "when timeout" do
          it "raise TimeoutError" do
            stub = stub_request(:patch, "https://example.com/users")
                   .to_raise(Faraday::TimeoutError)

            expect { dummy_client_class.new.patch("/users") }
              .to raise_error(dummy_client_class::TimeoutError)
            expect(stub).to have_been_requested
          end
        end

        context "when unexpected request error" do
          it "raise UnexpectedError" do
            stub = stub_request(:patch, "https://example.com/users")
                   .to_raise

            expect { dummy_client_class.new.patch("/users") }
              .to raise_error(dummy_client_class::UnexpectedError)
            expect(stub).to have_been_requested
          end
        end
      end

      describe "ResponseError" do
        describe "ResponseBody" do
          context "with ResponseBody" do
            it "raise exception object with parsed response" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 400, body: { message: "Bad Request" }.to_json)

              expected_exception = an_instance_of(dummy_client_class::BadRequestError)
                                   .and(have_attributes(status: 400, body: { message: "Bad Request" }))
              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(expected_exception)
              expect(stub).to have_been_requested
            end
          end

          context "without ResponseBody" do
            it "raise exception object with nil body" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 400)

              expected_exception = an_instance_of(dummy_client_class::BadRequestError)
                                   .and(have_attributes(status: 400, body: nil))
              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(expected_exception)
              expect(stub).to have_been_requested
            end
          end
        end

        describe "exception dispatch" do
          context "when 400" do
            it "raise BadRequestError" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 400)

              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(dummy_client_class::BadRequestError)
              expect(stub).to have_been_requested
            end
          end

          context "when 401" do
            it "raise UnauthorizedError" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 401)

              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(dummy_client_class::UnauthorizedError)
              expect(stub).to have_been_requested
            end
          end

          context "when 403" do
            it "raise ForbiddenError" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 403)

              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(dummy_client_class::ForbiddenError)
              expect(stub).to have_been_requested
            end
          end

          context "when 404" do
            it "raise NotFoundError" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 404)

              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(dummy_client_class::NotFoundError)
              expect(stub).to have_been_requested
            end
          end

          context "when 408" do
            it "raise RequestTimeoutError" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 408)

              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(dummy_client_class::RequestTimeoutError)
              expect(stub).to have_been_requested
            end
          end

          context "when 409" do
            it "raise ConflictError" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 409)

              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(dummy_client_class::ConflictError)
              expect(stub).to have_been_requested
            end
          end

          context "when 422" do
            it "raise UnprocessableEntityError" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 422)

              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(dummy_client_class::UnprocessableEntityError)
              expect(stub).to have_been_requested
            end
          end

          context "when 429" do
            it "raise TooManyRequestsError" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 429)

              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(dummy_client_class::TooManyRequestsError)
              expect(stub).to have_been_requested
            end
          end

          context "when 500" do
            it "raise ServerError" do
              stub = stub_request(:patch, "https://example.com/users")
                     .to_return(status: 500)

              expect { dummy_client_class.new.patch("/users") }
                .to raise_error(dummy_client_class::ServerError)
              expect(stub).to have_been_requested
            end
          end
        end
      end
    end

    describe "#delete" do
      describe "RequestParameter" do
        it "reflected in the query string" do
          stub = stub_request(:delete, "https://example.com/users")
                 .with(query: { page: 10, per: 1 })
                 .to_return(status: 200)

          dummy_client_class.new.delete("/users", params: { page: 10, per: 1 })
          expect(stub).to have_been_requested
        end
      end

      describe "RequestHeader" do
        describe "User-Agent" do
          it "Class name to be set (default)" do
            stub = stub_request(:delete, "https://example.com/users")
                   .with(headers: { "User-Agent" => "DummyClient" })

            dummy_client_class.new.delete("/users")
            expect(stub).to have_been_requested
          end
        end
      end

      describe "ResponseBody" do
        context "with ResponseBody" do
          it "parsed ResponseBody to be returned" do
            stub = stub_request(:delete, "https://example.com/users")
                   .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

            response = dummy_client_class.new.delete("/users")
            expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
            expect(stub).to have_been_requested
          end
        end

        context "without ResponseBody" do
          it "nil to be returned" do
            stub = stub_request(:delete, "https://example.com/users")
                   .to_return(status: 204)

            response = dummy_client_class.new.delete("/users")
            expect(response).to be_nil
            expect(stub).to have_been_requested
          end
        end
      end

      describe "RequestError" do
        context "when timeout" do
          it "raise TimeoutError" do
            stub = stub_request(:delete, "https://example.com/users")
                   .to_raise(Faraday::TimeoutError)

            expect { dummy_client_class.new.delete("/users") }
              .to raise_error(dummy_client_class::TimeoutError)
            expect(stub).to have_been_requested
          end
        end

        context "when unexpected request error" do
          it "raise UnexpectedError" do
            stub = stub_request(:delete, "https://example.com/users")
                   .to_raise

            expect { dummy_client_class.new.delete("/users") }
              .to raise_error(dummy_client_class::UnexpectedError)
            expect(stub).to have_been_requested
          end
        end
      end

      describe "ResponseError" do
        describe "ResponseBody" do
          context "with ResponseBody" do
            it "raise exception object with parsed response" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 400, body: { message: "Bad Request" }.to_json)

              expected_exception = an_instance_of(dummy_client_class::BadRequestError)
                                   .and(have_attributes(status: 400, body: { message: "Bad Request" }))
              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(expected_exception)
              expect(stub).to have_been_requested
            end
          end

          context "without ResponseBody" do
            it "raise exception object with nil body" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 400)

              expected_exception = an_instance_of(dummy_client_class::BadRequestError)
                                   .and(have_attributes(status: 400, body: nil))
              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(expected_exception)
              expect(stub).to have_been_requested
            end
          end
        end

        describe "exception dispatch" do
          context "when 400" do
            it "raise BadRequestError" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 400)

              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(dummy_client_class::BadRequestError)
              expect(stub).to have_been_requested
            end
          end

          context "when 401" do
            it "raise UnauthorizedError" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 401)

              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(dummy_client_class::UnauthorizedError)
              expect(stub).to have_been_requested
            end
          end

          context "when 403" do
            it "raise ForbiddenError" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 403)

              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(dummy_client_class::ForbiddenError)
              expect(stub).to have_been_requested
            end
          end

          context "when 404" do
            it "raise NotFoundError" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 404)

              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(dummy_client_class::NotFoundError)
              expect(stub).to have_been_requested
            end
          end

          context "when 408" do
            it "raise RequestTimeoutError" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 408)

              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(dummy_client_class::RequestTimeoutError)
              expect(stub).to have_been_requested
            end
          end

          context "when 409" do
            it "raise ConflictError" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 409)

              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(dummy_client_class::ConflictError)
              expect(stub).to have_been_requested
            end
          end

          context "when 422" do
            it "raise UnprocessableEntityError" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 422)

              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(dummy_client_class::UnprocessableEntityError)
              expect(stub).to have_been_requested
            end
          end

          context "when 429" do
            it "raise TooManyRequestsError" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 429)

              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(dummy_client_class::TooManyRequestsError)
              expect(stub).to have_been_requested
            end
          end

          context "when 500" do
            it "raise ServerError" do
              stub = stub_request(:delete, "https://example.com/users")
                     .to_return(status: 500)

              expect { dummy_client_class.new.delete("/users") }
                .to raise_error(dummy_client_class::ServerError)
              expect(stub).to have_been_requested
            end
          end
        end
      end
    end
  end
end
