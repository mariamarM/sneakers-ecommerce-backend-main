import 'dotenv/config'
import express    from 'express'
import cors       from 'cors'

import categoriesRoutes from './routes/categories.routes.js'
import productsRoutes   from './routes/products.routes.js'
import authRoutes       from './routes/auth.routes.js'
import ordersRoutes     from './routes/orders.routes.js'

const app  = express()
const PORT = process.env.PORT || 3000

// Middlewares globales
app.use(cors({ origin: process.env.FRONTEND_URL }))
app.use(express.json())

// Rutas
app.use('/api/auth',       authRoutes)
app.use('/api/categories', categoriesRoutes)
app.use('/api/products',   productsRoutes)
app.use('/api/orders',     ordersRoutes)

// Health check — útil para Railway y otros servicios de deploy
app.get('/health', (req, res) => res.json({ status: 'ok' }))

// Manejador global de errores
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).json({ error: err.message || 'Error interno del servidor' })
})

app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`)
})