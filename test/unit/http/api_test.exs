defmodule Gateway.HTTP.APITest do
  use Gateway.HTTPTestHelper

  test "GET /apis" do
    data =
      [
        Gateway.DB.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }}),
        Gateway.DB.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }})
      ]
      |> Enum.map(fn({:ok, e}) -> e end)

    conn =
      conn(:get, "/")
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.API.call([])

    expected_resp = %{
      meta: %{
        code: 200,
      },
      data: data
    }

    assert conn.status == 200
    assert conn.resp_body == Poison.encode!(expected_resp)
  end

  test "GET /apis/:api_id" do
    { :ok, data } =
      Gateway.DB.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }})

    conn =
      conn(:get, "/#{data.id}")
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.API.call([])

    expected_resp = %{
      meta: %{
        code: 200,
      },
      data: data
    }

    assert conn.status == 200
    assert conn.resp_body == Poison.encode!(expected_resp)
  end

  test "POST /apis" do
    contents = %{
      name: "Sample",
      request: %{
        host: "example.com",
        port: "4000",
        path: "/a/b/c",
        scheme: "http"
      }
    }

    conn =
      conn(:post, "/", Poison.encode!(contents))
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.API.call([])

    expected_resp = %{
      meta: %{
        code: 201,
      },
      data: contents
    }

    assert conn.status == 201
    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["id"]
    assert resp["updated_at"]
    assert resp["inserted_at"]

    assert resp["name"] == "Sample"
    assert resp["request"]["host"] == "example.com"
    assert resp["request"]["port"] == "4000"
    assert resp["request"]["path"] == "/a/b/c"
    assert resp["request"]["scheme"] == "http"
  end

  test "PUT /apis/:api_id" do
    { :ok, data } =
      Gateway.DB.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }})

    new_contents = %{
      name: "New name",
      request: %{
        host: "newhost.com",
        port: "4000",
        path: "/new/path/",
        scheme: "https"
      }
    }

    conn =
      conn(:put, "/#{data.id}", Poison.encode!(new_contents))
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.API.call([])

    expected_resp = %{
      meta: %{
        code: 200,
      },
      data: new_contents
    }

    assert conn.status == 200
    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["id"]
    assert resp["updated_at"]

    assert resp["name"] == "New name"
    assert resp["request"]["host"] == "newhost.com"
    assert resp["request"]["port"] == "4000"
    assert resp["request"]["path"] == "/new/path/"
    assert resp["request"]["scheme"] == "https"
  end

  test "DELETE /apis/:api_id" do
    { :ok, data } =
      Gateway.DB.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }})

    conn =
      conn(:delete, "/#{data.id}")
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.API.call([])

    expected_resp = %{
      meta: %{
        description: "API was deleted",
        code: 200
      },
      data: data
    }

    resp = Poison.decode!(conn.resp_body)

    assert conn.status == 200
    assert resp["data"]["id"] == data.id
    assert resp["meta"]["description"] == "Resource was deleted"
  end
end