import { Router } from 'express'
import { getProducts, getProductBySlug, createProduct, updateProduct, deleteProduct } from '../controllers/products.controller.js'
import { authMiddleware }  from '../middleware/auth.middleware.js'
import { adminMiddleware } from '../middleware/admin.middleware.js'
import { upload }          from '../middleware/upload.middleware.js'

const router = Router()

router.get('/',         getProducts)
router.get('/:slug',    getProductBySlug)
router.post('/',        authMiddleware, adminMiddleware, upload.single('image'), createProduct)
router.put('/:id',      authMiddleware, adminMiddleware, upload.single('image'), updateProduct)
router.delete('/:id',   authMiddleware, adminMiddleware, deleteProduct)

export default router