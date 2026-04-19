-- =============================================================================
-- KICKstore E-Commerce Database Schema
-- Complete setup with tables, RLS policies, indexes, and test data
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. TABLES CREATION
-- =============================================================================

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  slug VARCHAR(100) NOT NULL UNIQUE,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE categories IS 'Product categories for organizing sneakers';
COMMENT ON COLUMN categories.slug IS 'URL-friendly identifier for the category';

-- Products table
CREATE TABLE IF NOT EXISTS products (
  id BIGSERIAL PRIMARY KEY,
  category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  sku VARCHAR(50) NOT NULL UNIQUE,
  price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
  stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  image_url TEXT,
  brand VARCHAR(100),
  size_range VARCHAR(100),
  color VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  rating DECIMAL(3, 2) CHECK (rating >= 0 AND rating <= 5),
  total_reviews INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE products IS 'Sneaker products available in the store';
COMMENT ON COLUMN products.stock_quantity IS 'Available units in inventory';
COMMENT ON COLUMN products.rating IS 'Average customer rating out of 5';

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  order_number VARCHAR(20) NOT NULL UNIQUE,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
  total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
  tax_amount DECIMAL(10, 2) DEFAULT 0,
  shipping_cost DECIMAL(10, 2) DEFAULT 0,
  discount_amount DECIMAL(10, 2) DEFAULT 0,
  customer_name VARCHAR(255) NOT NULL,
  customer_email VARCHAR(255) NOT NULL,
  customer_phone VARCHAR(20),
  shipping_address TEXT NOT NULL,
  shipping_city VARCHAR(100),
  shipping_country VARCHAR(100),
  shipping_postal_code VARCHAR(20),
  notes TEXT,
  payment_method VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE orders IS 'Customer orders';
COMMENT ON COLUMN orders.order_number IS 'Unique customer-facing order identifier (e.g., KS-2024-001)';
COMMENT ON COLUMN orders.status IS 'Current order status';

-- Order Items table (line items)
CREATE TABLE IF NOT EXISTS order_items (
  id BIGSERIAL PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price > 0),
  subtotal DECIMAL(12, 2) NOT NULL CHECK (subtotal > 0),
  size VARCHAR(10),
  color VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE order_items IS 'Individual items in an order';
COMMENT ON COLUMN order_items.size IS 'Shoe size of the ordered product';
COMMENT ON COLUMN order_items.unit_price IS 'Price per unit at time of order';

-- =============================================================================
-- 2. INDEXES FOR PERFORMANCE
-- =============================================================================

-- Categories indexes
CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_created_at ON categories(created_at DESC);

-- Products indexes
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_is_active ON products(is_active) WHERE is_active = true;
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_rating ON products(rating DESC);
CREATE INDEX idx_products_created_at ON products(created_at DESC);
-- Full-text search index
CREATE INDEX idx_products_search ON products USING GIN(
  to_tsvector('spanish', COALESCE(name, '') || ' ' || COALESCE(description, ''))
);

-- Orders indexes
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_order_number ON orders(order_number);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_email ON orders(customer_email);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

-- Order Items indexes
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_created_at ON order_items(created_at DESC);

-- =============================================================================
-- 3. VIEWS FOR COMMON QUERIES
-- =============================================================================

-- View for products with category information
CREATE OR REPLACE VIEW products_with_category AS
SELECT 
  p.id,
  p.name,
  p.description,
  p.sku,
  p.price,
  p.stock_quantity,
  p.brand,
  p.color,
  p.rating,
  p.total_reviews,
  p.is_active,
  c.id as category_id,
  c.name as category_name,
  c.slug as category_slug,
  p.created_at,
  p.updated_at
FROM products p
JOIN categories c ON p.category_id = c.id;

-- View for order summaries
CREATE OR REPLACE VIEW order_summaries AS
SELECT 
  o.id,
  o.order_number,
  o.user_id,
  o.status,
  o.total_amount,
  o.customer_name,
  o.customer_email,
  COUNT(oi.id) as item_count,
  SUM(oi.quantity) as total_quantity,
  o.created_at,
  o.updated_at
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, o.order_number, o.user_id, o.status, o.total_amount, 
         o.customer_name, o.customer_email, o.created_at, o.updated_at;

-- View for inventory status
CREATE OR REPLACE VIEW inventory_status AS
SELECT 
  p.id,
  p.name,
  p.sku,
  p.stock_quantity,
  CASE 
    WHEN p.stock_quantity = 0 THEN 'Out of Stock'
    WHEN p.stock_quantity < 10 THEN 'Low Stock'
    WHEN p.stock_quantity < 50 THEN 'Medium Stock'
    ELSE 'In Stock'
  END as stock_status,
  c.name as category_name
FROM products p
JOIN categories c ON p.category_id = c.id;

-- =============================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- ============ CATEGORIES - Public read access ============
CREATE POLICY categories_read_all ON categories
  FOR SELECT
  USING (true);

CREATE POLICY categories_insert_admin ON categories
  FOR INSERT
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY categories_update_admin ON categories
  FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY categories_delete_admin ON categories
  FOR DELETE
  USING (auth.jwt() ->> 'role' = 'admin');

-- ============ PRODUCTS - Public read access ============
CREATE POLICY products_read_active ON products
  FOR SELECT
  USING (is_active = true OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY products_insert_admin ON products
  FOR INSERT
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY products_update_admin ON products
  FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY products_delete_admin ON products
  FOR DELETE
  USING (auth.jwt() ->> 'role' = 'admin');

-- ============ ORDERS - User-specific access ============
CREATE POLICY orders_read_own ON orders
  FOR SELECT
  USING (
    auth.uid() = user_id 
    OR auth.jwt() ->> 'role' = 'admin'
  );

CREATE POLICY orders_insert_user ON orders
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY orders_update_own ON orders
  FOR UPDATE
  USING (
    auth.uid() = user_id 
    OR auth.jwt() ->> 'role' = 'admin'
  )
  WITH CHECK (
    auth.uid() = user_id 
    OR auth.jwt() ->> 'role' = 'admin'
  );

-- Admin can view all orders
CREATE POLICY orders_read_admin ON orders
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- ============ ORDER_ITEMS - Inherit from orders ============
CREATE POLICY order_items_read_own ON order_items
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders 
      WHERE orders.id = order_items.order_id 
      AND (orders.user_id = auth.uid() OR auth.jwt() ->> 'role' = 'admin')
    )
  );

CREATE POLICY order_items_insert_user ON order_items
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders 
      WHERE orders.id = order_items.order_id 
      AND orders.user_id = auth.uid()
    )
  );

-- =============================================================================
-- 5. TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for categories
CREATE TRIGGER categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for products
CREATE TRIGGER products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for orders
CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate order totals when items are added
CREATE OR REPLACE FUNCTION recalculate_order_total()
RETURNS TRIGGER AS $$
DECLARE
  subtotal DECIMAL(12, 2);
BEGIN
  SELECT COALESCE(SUM(subtotal), 0) INTO subtotal
  FROM order_items
  WHERE order_id = COALESCE(NEW.order_id, OLD.order_id);
  
  UPDATE orders 
  SET total_amount = subtotal + COALESCE(tax_amount, 0) + COALESCE(shipping_cost, 0) - COALESCE(discount_amount, 0)
  WHERE id = COALESCE(NEW.order_id, OLD.order_id);
  
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for recalculating order totals
CREATE TRIGGER order_items_recalculate_total
  AFTER INSERT OR UPDATE OR DELETE ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION recalculate_order_total();

-- Function to decrease stock when order is confirmed
CREATE OR REPLACE FUNCTION decrease_stock_on_order()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'confirmed' AND OLD.status != 'confirmed' THEN
    UPDATE products
    SET stock_quantity = stock_quantity - (
      SELECT COALESCE(SUM(quantity), 0)
      FROM order_items
      WHERE order_id = NEW.id
    )
    WHERE id IN (
      SELECT product_id FROM order_items WHERE order_id = NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for decreasing stock
CREATE TRIGGER decrease_stock
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION decrease_stock_on_order();

-- =============================================================================
-- 6. TEST DATA
-- =============================================================================

-- Insert categories
INSERT INTO categories (name, slug, description, image_url) VALUES
  ('Running', 'running', 'Zapatillas de running para entrenamiento y competencia', 'https://via.placeholder.com/300?text=Running'),
  ('Basketball', 'basketball', 'Zapatillas de baloncesto de máxima performance', 'https://via.placeholder.com/300?text=Basketball'),
  ('Casual', 'casual', 'Zapatillas casuales para uso diario', 'https://via.placeholder.com/300?text=Casual'),
  ('Training', 'training', 'Zapatillas de entrenamiento de alta durabilidad', 'https://via.placeholder.com/300?text=Training'),
  ('Skateboard', 'skateboard', 'Zapatillas especializadas para skateboarding', 'https://via.placeholder.com/300?text=Skateboard')
ON CONFLICT (slug) DO NOTHING;

-- Insert products
INSERT INTO products (category_id, name, description, sku, price, stock_quantity, brand, color, rating, total_reviews, is_active) VALUES
  (1, 'UltraBoost Pro 2024', 'Zapatilla de running con tecnología Boost mejorada para máxima comodidad', 'UB-PRO-2024-01', 189.99, 45, 'Adidas', 'Negro/Blanco', 4.8, 234, true),
  (1, 'Nike Pegasus 41', 'Zapatilla responsive ideal para corredores de larga distancia', 'NK-PEG-41-01', 149.99, 67, 'Nike', 'Azul/Blanco', 4.7, 189, true),
  (2, 'Air Jordan XXXVIII', 'Zapatilla de basketball con diseño icónico y protección superior', 'AJ-38-BLK-01', 229.99, 23, 'Nike', 'Negro/Rojo', 4.9, 156, true),
  (2, 'Curry Flow 10', 'Zapatilla de baloncesto con excelente tracción y estabilidad', 'CF-10-WHT-01', 199.99, 38, 'Under Armour', 'Blanco/Oro', 4.6, 127, true),
  (3, 'Stan Smith Reimagined', 'Clásica casual con detalles modernos y acabados premium', 'SS-REIM-01', 119.99, 92, 'Adidas', 'Blanco/Verde', 4.5, 312, true),
  (3, 'Chuck Taylor All Star Pro', 'Icónica zapatilla casual con soporte mejorado', 'CT-PRO-01', 89.99, 156, 'Converse', 'Negro', 4.4, 245, true),
  (4, 'Metcon 9', 'Zapatilla de cross-training con máxima estabilidad', 'MET-9-01', 169.99, 34, 'Nike', 'Gris/Negro', 4.8, 198, true),
  (4, 'CrossFit Nano X2', 'Diseñada para movimientos multidireccionales', 'CFN-X2-01', 179.99, 41, 'Reebok', 'Azul/Blanco', 4.7, 176, true),
  (5, 'SB Dunk Low Pro', 'Zapatilla de skateboarding con grip excepcional', 'SB-DL-PRO-01', 139.99, 28, 'Nike', 'Rojo/Blanco', 4.6, 143, true),
  (5, 'New Balance 574 Skate', 'Zapatilla skate con comodidad de uso diario', 'NB-574-SK-01', 129.99, 52, 'New Balance', 'Verde/Negro', 4.5, 98, true),
  (1, 'Saucony Endorphin Speed 3', 'Zapatilla de running para carreras rápidas', 'SAU-ES3-01', 159.99, 39, 'Saucony', 'Naranja/Negro', 4.7, 167, true),
  (2, 'Kyrie Infinity', 'Zapatilla de basketball con excelente maniobrabilidad', 'KY-INF-01', 219.99, 19, 'Nike', 'Púrpura/Oro', 4.8, 134, true)
ON CONFLICT (sku) DO NOTHING;

-- Insert test users orders (using example UUIDs)
INSERT INTO orders (id, user_id, order_number, status, customer_name, customer_email, customer_phone, shipping_address, shipping_city, shipping_country, shipping_postal_code, total_amount, payment_method) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'KS-2024-001', 'delivered', 'Juan García', 'juan.garcia@email.com', '(+34) 912 34 56 78', 'Calle Principal 123', 'Madrid', 'España', '28001', 379.98, 'credit_card'),
  ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'KS-2024-002', 'shipped', 'María López', 'maria.lopez@email.com', '(+34) 933 45 67 89', 'Avenida Catalunya 456', 'Barcelona', 'España', '08002', 289.97, 'paypal'),
  ('550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'KS-2024-003', 'pending', 'Juan García', 'juan.garcia@email.com', '(+34) 912 34 56 78', 'Calle Principal 123', 'Madrid', 'España', '28001', 169.99, 'debit_card'),
  ('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440003', 'KS-2024-004', 'confirmed', 'Carlos Mendez', 'carlos.mendez@email.com', '(+34) 954 12 34 56', 'Plaza del Centro 789', 'Sevilla', 'España', '41001', 519.97, 'credit_card'),
  ('550e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440004', 'KS-2024-005', 'delivered', 'Ana Rodríguez', 'ana.rodriguez@email.com', '(+34) 871 23 45 67', 'Paseo Marítimo 321', 'Valencia', 'España', '46001', 249.98, 'apple_pay')
ON CONFLICT (id) DO NOTHING;

-- Insert order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal, size, color) VALUES
  -- Order 1 (Juan García - KS-2024-001)
  ('550e8400-e29b-41d4-a716-446655440001', 1, 1, 189.99, 189.99, '43', 'Negro/Blanco'),
  ('550e8400-e29b-41d4-a716-446655440001', 5, 1, 119.99, 119.99, '42', 'Blanco/Verde'),
  ('550e8400-e29b-41d4-a716-446655440001', 6, 1, 69.99, 69.99, '44', 'Negro'),
  
  -- Order 2 (María López - KS-2024-002)
  ('550e8400-e29b-41d4-a716-446655440002', 3, 1, 229.99, 229.99, '41', 'Negro/Rojo'),
  ('550e8400-e29b-41d4-a716-446655440002', 6, 1, 59.98, 59.98, '39', 'Negro'),
  
  -- Order 3 (Juan García - KS-2024-003)
  ('550e8400-e29b-41d4-a716-446655440003', 2, 1, 149.99, 149.99, '42', 'Azul/Blanco'),
  ('550e8400-e29b-41d4-a716-446655440003', 10, 1, 19.99, 19.99, '43', 'Verde/Negro'),
  
  -- Order 4 (Carlos Mendez - KS-2024-004)
  ('550e8400-e29b-41d4-a716-446655440004', 4, 2, 199.99, 399.98, '40', 'Blanco/Oro'),
  ('550e8400-e29b-41d4-a716-446655440004', 7, 1, 119.99, 119.99, '42', 'Gris/Negro'),
  
  -- Order 5 (Ana Rodríguez - KS-2024-005)
  ('550e8400-e29b-41d4-a716-446655440005', 9, 1, 139.99, 139.99, '38', 'Rojo/Blanco'),
  ('550e8400-e29b-41d4-a716-446655440005', 11, 1, 109.99, 109.99, '43', 'Naranja/Negro')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 7. SUMMARY OF CREATED OBJECTS
-- =============================================================================

/*
TABLAS CREADAS:
- categories: Categorías de productos
- products: Productos (zapatillas)
- orders: Pedidos de clientes
- order_items: Items individuales dentro de un pedido

CARACTERÍSTICAS DE SEGURIDAD (RLS):
- categories: Lectura pública, edición solo para admins
- products: Lectura de productos activos (admins ven todos), edición solo admins
- orders: Lectura propia (usuarios ven sus pedidos), admins ven todos
- order_items: Heredan permisos de la orden asociada

ÍNDICES CREADOS (12 total):
- Para búsqueda rápida por categoría, SKU, marca, estado
- Índices de full-text search en español para productos
- Índices de ordenamiento por fecha y rating
- Índices compuestos para consultas frecuentes

VISTAS CREADAS (3 total):
- products_with_category: Productos con información de categoría
- order_summaries: Resumen de órdenes con conteos
- inventory_status: Estado actual del inventario

TRIGGERS CREADOS (4 total):
- Actualización automática de timestamps
- Cálculo automático de totales de orden
- Disminución de stock al confirmar pedido

DATOS DE PRUEBA:
- 5 categorías de zapatillas
- 12 productos variados
- 5 órdenes de ejemplo con 11 items totales
*/
