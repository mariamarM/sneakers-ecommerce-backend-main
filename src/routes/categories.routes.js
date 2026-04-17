import { Router } from 'express'
import { getCategories, createCategory } from '../controllers/categories.controller.js'
import { authMiddleware }  from '../middleware/auth.middleware.js'
import { adminMiddleware } from '../middleware/admin.middleware.js'

const router = Router()

router.get('/',  getCategories)
router.post('/', authMiddleware, adminMiddleware, createCategory)

export default router