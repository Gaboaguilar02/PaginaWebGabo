json.extract! product, :id, :nombre, :descripcion, :precio, :stock, :created_at, :updated_at
json.url product_url(product, format: :json)
