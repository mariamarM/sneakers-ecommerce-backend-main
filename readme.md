# KICKstore — Backend API

API REST para el e-commerce de zapatillas desarrollado con Node.js + Express.

## Tecnologías

- Node.js 22 + ES Modules
- Express 4
- Supabase (PostgreSQL + Auth)
- Cloudinary (almacenamiento de imágenes)

## Requisitos previos

- Node.js v18 o superior
- Cuenta en [Supabase](https://supabase.com) con proyecto creado
- Cuenta en [Cloudinary](https://cloudinary.com) (free tier)
- MCP de Supabase configurado en Claude Desktop

## Instalación

1. Clona el repositorio
2. Instala las dependencias:
   npm install
3. Copia el archivo de variables de entorno:
   cp .env.example .env
4. Rellena el .env con tus credenciales
5. Configura el MCP de Supabase en Claude Desktop (ver sección siguiente)
6. Crea el esquema de base de datos con Claude (ver sección siguiente)

## Configuración del MCP de Supabase

Edita el archivo de configuración de Claude Desktop:

macOS:
~/Library/Application Support/Claude/claude_desktop_config.json

Windows:
%APPDATA%\Claude\claude_desktop_config.json

Añade esta configuración:

{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--project-ref=TU_PROJECT_ID"
      ],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "TU_PERSONAL_ACCESS_TOKEN"
      }
    }
  }
}

En macOS usa la ruta absoluta de npx:
"command": "/usr/local/bin/npx"

Reinicia Claude Desktop y verifica que el MCP está activo.

## Crear el esquema de base de datos con Claude

Una vez el MCP esté activo, pide a Claude que cree el esquema:

> "Crea el esquema completo de la base de datos para el e-commerce de zapatillas KICKstore con las tablas categories, products, orders y order_items. Incluye RLS, índices y datos de prueba."

Claude ejecutará las migraciones automáticamente en tu proyecto de Supabase.

## Arrancar el servidor

Desarrollo (con hot reload):
npm run dev

Producción:
npm start

El servidor arrancará en http://localhost:3000

## Endpoints disponibles

### Auth
- POST /api/auth/register
- POST /api/auth/login
- GET  /api/auth/profile

### Categorías
- GET  /api/categories
- POST /api/categories (admin)

### Productos
- GET    /api/products
- GET    /api/products/:slug
- POST   /api/products (admin)
- PUT    /api/products/:id (admin)
- DELETE /api/products/:id (admin)

### Pedidos
- POST  /api/orders
- GET   /api/orders/my-orders
- GET   /api/orders (admin)
- PATCH /api/orders/:id/status (admin)

## Health check

GET /health → { "status": "ok" }