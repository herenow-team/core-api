defmodule HerenowWeb.ClientsRegistrationTest do
  use Herenow.DataCase
  use Bamboo.Test

  alias Faker.{Name, Address, Commerce, Internet, Company}
  alias Herenow.Clients.Storage.{Mutator, Loader}
  alias Herenow.Clients.WelcomeEmail
  alias Herenow.Clients

  @valid_attrs %{
    "street_number" => Address.building_number(),
    "is_company" => true,
    "name" => Name.name(),
    "password" => "some password",
    "legal_name" => Company.name(),
    "segment" => Commerce.department(),
    "state" => Address.state(),
    "street_name" => Address.street_name(),
    "captcha" => "valid",
    "postal_code" => "12345678",
    "city" => Address.city(),
    "email" => Internet.email()
  }

  def client_fixture(attrs \\ %{}) do
    {:ok, client} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Mutator.create()

    client
  end

  describe "register/1" do
    test "missing keys" do
      attrs =
        @valid_attrs
        |> Map.drop(["postal_code", "city", "email"])

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "city",
              "message" => "can't be blank",
              "type" => :required
            },
            %{
              "field" => "email",
              "message" => "can't be blank",
              "type" => :required
            },
            %{
              "field" => "postal_code",
              "message" => "can't be blank",
              "type" => :required
            }
          ]}}

      assert actual == expected
    end

    test "invalid type of keys" do
      keys = Map.keys(@valid_attrs)

      Enum.each(keys, fn key ->
        value = Map.get(@valid_attrs, key)

        expected =
          {:error,
           {:validation,
            [
              %{
                "field" => key,
                "message" => "is invalid",
                "type" => :cast
              }
            ]}}

        if is_boolean(value) do
          attrs =
            @valid_attrs
            |> Map.put(key, "some string")

          actual = Clients.register(attrs)
          assert actual == expected
        else
          attrs =
            @valid_attrs
            |> Map.put(key, 9)

          actual = Clients.register(attrs)
          assert actual == expected
        end
      end)
    end

    test "invalid captcha" do
      attrs =
        @valid_attrs
        |> Map.put("captcha", "invalid")

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => nil,
              "message" => "Invalid captcha",
              "type" => :invalid_captcha
            }
          ]}}

      assert actual == expected
    end

    test "email should be unique" do
      client = client_fixture()

      attrs =
        @valid_attrs
        |> Map.put("email", client.email)

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "email",
              "message" => "has already been taken",
              "type" => :unique
            }
          ]}}

      assert actual == expected
    end

    test "email should have less than 255 characters" do
      email =
        @valid_attrs
        |> Map.get("email")
        |> String.pad_leading(256, "abc")

      attrs =
        @valid_attrs
        |> Map.put("email", email)

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "email",
              "message" => "should be at most 254 character(s)",
              "type" => :length
            }
          ]}}

      assert actual == expected
    end

    test "email should have a @" do
      attrs =
        @valid_attrs
        |> Map.put("email", "invalidemail")

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "email",
              "message" => "has invalid format",
              "type" => :format
            }
          ]}}

      assert actual == expected
    end

    test "postal_code should have exact 8 characters, less should return error" do
      attrs =
        @valid_attrs
        |> Map.put("postal_code", "1234")

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "postal_code",
              "message" => "should be 8 character(s)",
              "type" => :length
            }
          ]}}

      assert actual == expected
    end

    test "postal_code should have exact 8 characters, more should return error" do
      attrs =
        @valid_attrs
        |> Map.put("postal_code", "123456789")

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "postal_code",
              "message" => "should be 8 character(s)",
              "type" => :length
            }
          ]}}

      assert actual == expected
    end

    test "password should have at least 8 characters" do
      attrs =
        @valid_attrs
        |> Map.put("password", "abcdefg")

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "password",
              "message" => "should be at least 8 character(s)",
              "type" => :length
            }
          ]}}

      assert actual == expected
    end

    test "should return the client's information" do
      {:ok, client} = Clients.register(@valid_attrs)

      assert client.street_number == @valid_attrs["street_number"]
      assert client.postal_code == @valid_attrs["postal_code"]
      assert client.city == @valid_attrs["city"]
      assert client.email == @valid_attrs["email"]
      assert client.is_company == @valid_attrs["is_company"]
      assert client.legal_name == @valid_attrs["legal_name"]
      assert client.name == @valid_attrs["name"]
      assert client.segment == @valid_attrs["segment"]
      assert client.state == @valid_attrs["state"]
      assert client.street_name == @valid_attrs["street_name"]
    end

    test "should persist the client" do
      {:ok, client} = Clients.register(@valid_attrs)
      persisted_client = Loader.get!(client.id)

      assert client.id == persisted_client.id
      assert client.street_number == persisted_client.street_number
      assert client.postal_code == persisted_client.postal_code
      assert client.city == persisted_client.city
      assert client.email == persisted_client.email
      assert client.is_company == persisted_client.is_company
      assert client.legal_name == persisted_client.legal_name
      assert client.name == persisted_client.name
      assert client.segment == persisted_client.segment
      assert client.state == persisted_client.state
      assert client.street_name == persisted_client.street_name
      assert client.inserted_at == persisted_client.inserted_at
      assert client.updated_at == persisted_client.updated_at
    end

    test "after registering, the user gets a welcome email" do
      {:ok, client} = Clients.register(@valid_attrs)

      assert_delivered_email(WelcomeEmail.create(client))
    end
  end
end