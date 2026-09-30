# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products" do
  # The navigation layout requires a full course and a kids edition to exist
  let!(:race_edition) { FactoryBot.create(:race_edition, :full_course, date: "2026-09-12") }
  let!(:kids_edition) { FactoryBot.create(:race_edition, :kids_race, date: "2026-09-12") }

  let!(:product) { FactoryBot.create(:product, description: "Race Shirt", price: 25, quantity: 10) }
  let!(:product_image) do
    FactoryBot.create(:product_image, product: product, url: "https://example.com/shirt.jpg", alt_text: "A race shirt")
  end

  describe "GET /products" do
    it "lists the products with their images" do
      get products_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("All Products")
      expect(response.body).to include("Race Shirt")
      expect(response.body).to include("https://example.com/shirt.jpg")
      expect(response.body).to include("Cost: $25")
    end
  end

  describe "GET /products/:id" do
    it "shows the product" do
      get product_path(product)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Race Shirt")
      expect(response.body).to include("Price: $25")
      expect(response.body).to include("https://example.com/shirt.jpg")
    end
  end

  describe "GET /products/new" do
    it "renders the form" do
      get new_product_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create a new Product")
    end
  end

  describe "GET /products/:id/edit" do
    it "renders the form" do
      get edit_product_path(product)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit Product")
    end
  end
end
