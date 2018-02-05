defmodule HerenowWeb.ErrorView do
  use HerenowWeb, :view

  def render("404.json", _assigns) do
    %{message: "Not found"}
  end

  def render("401.json", %{reason: reason}) do
    %{message: reason}
  end

  def render("500.json", _assigns) do
    %{message: "Internal server error"}
  end

  def template_not_found(_template, assigns) do
    render "500.json", assigns
  end
end
