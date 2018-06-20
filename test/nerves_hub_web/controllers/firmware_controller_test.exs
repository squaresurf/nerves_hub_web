defmodule NervesHubWeb.FirmwareControllerTest do
  use NervesHubWeb.ConnCase.Browser

  describe "index" do
    test "lists all firmwares", %{conn: conn} do
      conn = get(conn, firmware_path(conn, :index))
      assert html_response(conn, 200) =~ "Firmware"
    end
  end

  describe "upload firmware form" do
    test "renders form with valid request params", %{conn: conn} do
      conn = get(conn, firmware_path(conn, :upload))

      assert html_response(conn, 200) =~ "Upload Firmware"
    end
  end

  describe "upload firmware" do
    test "redirects after successful upload", %{conn: conn} do
      upload = %Plug.Upload{
        path: "test/fixtures/firmware/signed-key1.fw",
        filename: "signed-key1.fw"
      }

      # check that we end up in the right place
      create_conn = post(conn, "/firmware/upload", %{"firmware" => %{"file" => upload}})
      assert redirected_to(create_conn, 302) =~ firmware_path(conn, :index)

      # check that the proper creation side effects took place
      conn = get(conn, firmware_path(conn, :index))
      # starter is the product for the test firmware
      assert html_response(conn, 200) =~ "starter"
    end

    test "error if corrupt firmware uploaded", %{conn: conn} do
      upload = %Plug.Upload{
        path: "test/fixtures/firmware/corrupt.fw",
        filename: "corrupt.fw"
      }

      # check for the error message
      conn = post(conn, "/firmware/upload", %{"firmware" => %{"file" => upload}})

      assert html_response(conn, 200) =~
               "Firmware corrupt, signature invalid or missing public key"
    end

    test "error if tenant keys do not match firmware", %{conn: conn} do
      upload = %Plug.Upload{
        path: "test/fixtures/firmware/signed-other-key.fw",
        filename: "signed-other-key.fw"
      }

      # check for the error message
      conn = post(conn, "/firmware/upload", %{"firmware" => %{"file" => upload}})

      assert html_response(conn, 200) =~
               "Firmware corrupt, signature invalid or missing public key"
    end
  end
end