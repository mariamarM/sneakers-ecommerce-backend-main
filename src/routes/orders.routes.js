import { Router } from 'express'
import { createOrder, getUserOrders, getAllOrders, updateOrderStatus } from '../controllers/orders.controller.js'
import { authMiddleware }  from '../middleware/auth.middleware.js'
import { adminMiddleware } from '../middleware/admin.middleware.js'

const router = Router()

router.post('/',          authMiddleware, createOrder)
router.get('/my-orders',  authMiddleware, getUserOrders)
router.get('/',           authMiddleware, adminMiddleware, getAllOrders)
router.patch('/:id/status', authMiddleware, adminMiddleware, updateOrderStatus)

export default router