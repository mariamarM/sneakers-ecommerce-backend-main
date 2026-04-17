# KICKstore — Esquema de base de datos

Este documento contiene los prompts exactos para que Claude cree el esquema completo de la base de datos via MCP de Supabase.

## Requisitos previos

1. Proyecto creado en Supabase Cloud
2. MCP de Supabase configurado en Claude Desktop
3. Claude Desktop reconoce tu proyecto (prueba: *"Lista mis proyectos de Supabase"*)

---

## Prompt 1 — Tabla categories

```
Crea la tabla categories en Supabase con estos campos:
- id (uuid, primary key, gen_random_uuid())
- name (text, not null, unique)
- slug (text, not null, unique)
- description (text, nullable)
- created_at (timestamptz, default now())

Activa RLS. Cualquier usuario puede leer. Solo service_role puede insertar, actualizar y eliminar.
Crea un índice en slug.
```

---

## Prompt 2 — Tabla products

```
Crea la tabla products en Supabase con estos campos:
- id (uuid, primary key, gen_random_uuid())
- category_id (uuid, foreign key a categories.id, ON DELETE RESTRICT)
- name (text, not null)
- slug (text, not null, unique)
- description (text, nullable)
- price (numeric(10,2), not null, mayor que 0)
- stock (integer, not null, default 0, mayor o igual que 0)
- image_url (text, nullable)
- brand (text, nullable)
- sizes (text[], default '{}')
- is_active (boolean, not null, default true)
- created_at (timestamptz, default now())
- updated_at (timestamptz, default now())

Crea un trigger que actualice updated_at automáticamente en cada UPDATE.
Activa RLS. Cualquier usuario puede leer productos activos. Solo service_role puede insertar, actualizar y eliminar.
Crea índices en category_id, slug e is_active.
```

---

## Prompt 3 — Tablas orders y order_items

```
Crea la tabla orders en Supabase con estos campos:
- id (uuid, primary key, gen_random_uuid())
- user_id (uuid, foreign key a auth.users.id, ON DELETE RESTRICT)
- status (text, not null, default 'pending', valores permitidos: pending/confirmed/shipped/delivered/cancelled)
- total_amount (numeric(10,2), not null, mayor o igual que 0)
- shipping_address (text, nullable)
- notes (text, nullable)
- created_at (timestamptz, default now())
- updated_at (timestamptz, default now())

Crea también la tabla order_items con estos campos:
- id (uuid, primary key, gen_random_uuid())
- order_id (uuid, foreign key a orders.id, ON DELETE CASCADE)
- product_id (uuid, foreign key a products.id, ON DELETE RESTRICT)
- quantity (integer, not null, mayor que 0)
- unit_price (numeric(10,2), not null, mayor que 0)
- size (text, nullable)
- created_at (timestamptz, default now())

Activa RLS en ambas tablas. Un usuario solo puede ver y crear sus propios pedidos.
Solo service_role puede hacer operaciones de admin.
Crea índices en user_id, status y created_at en orders. En order_items en order_id y product_id.
```

---

## Prompt 4 — Funciones RPC

```
Crea estas funciones PostgreSQL con SECURITY DEFINER en Supabase:

1. soft_delete_product(product_id uuid) — marca is_active = false en products

2. insert_product(p_name, p_price, p_category_id, p_description, p_stock, p_brand, p_sizes, p_image_url)
   — inserta un producto y genera el slug automáticamente, devuelve el registro creado

3. update_product(p_id, p_name, p_description, p_price, p_stock, p_brand, p_category_id, p_sizes, p_image_url, p_is_active)
   — actualiza solo los campos no nulos usando COALESCE, devuelve el registro actualizado

4. get_all_orders() — devuelve todos los pedidos ordenados por created_at DESC

5. update_order_status(p_order_id uuid, p_status text) — actualiza el estado de un pedido, devuelve el registro actualizado
```

---

## Prompt 5 — Datos de prueba

```
Inserta datos de prueba en Supabase:

Categorías: Running, Basketball, Lifestyle, Training (con slugs y descripciones)

Productos (2 por categoría aproximadamente) con nombre, slug, descripción, precio, stock, brand y array de tallas.
Los image_url pueden quedar vacíos — se actualizarán desde el panel de administración.
```

---

## Usuarios de prueba

Crea los usuarios directamente desde el dashboard de Supabase (Authentication → Users):

| Email | Contraseña | Rol |
|---|---|---|
| user@test.com | 123456 | user |
| admin@test.com | 123456 | admin |

Después de crearlos, actualiza sus metadatos via MCP:

```
Actualiza en Supabase el raw_user_meta_data del usuario con email user@test.com 
con: { "full_name": "Usuario Test", "role": "user", "email_verified": true }

Haz lo mismo para admin@test.com con role: "admin" y full_name: "Admin User"
```