import { supabase } from '../config/supabase.js'

export const createOrder = async (req, res) => {
  const { items, shipping_address, notes } = req.body
  const user_id = req.user.id

  if (!items || items.length === 0) {
    return res.status(400).json({ error: 'El pedido debe tener al menos un producto' })
  }

  // Recuperamos los precios actuales de los productos
  const productIds = items.map(i => i.product_id)
  const { data: products, error: productsError } = await supabase
    .from('products')
    .select('id, price, stock, name')
    .in('id', productIds)

  if (productsError) return res.status(500).json({ error: productsError.message })

  // Validamos stock y calculamos el total
  for (const item of items) {
    const product = products.find(p => p.id === item.product_id)
    if (!product) return res.status(400).json({ error: `Producto no encontrado: ${item.product_id}` })
    if (product.stock < item.quantity) {
      return res.status(400).json({ error: `Stock insuficiente para: ${product.name}` })
    }
  }

  const total_amount = items.reduce((sum, item) => {
    const product = products.find(p => p.id === item.product_id)
    return sum + product.price * item.quantity
  }, 0)

  // Creamos el pedido
  const { data: order, error: orderError } = await supabase
    .from('orders')
    .insert({ user_id, total_amount, shipping_address, notes })
    .select()
    .single()

  if (orderError) return res.status(500).json({ error: orderError.message })

  // Insertamos las líneas con el precio histórico
  const orderItems = items.map(item => ({
    order_id:   order.id,
    product_id: item.product_id,
    quantity:   item.quantity,
    size:       item.size,
    unit_price: products.find(p => p.id === item.product_id).price
  }))

  const { error: itemsError } = await supabase
    .from('order_items')
    .insert(orderItems)

  if (itemsError) return res.status(500).json({ error: itemsError.message })

  res.status(201).json({ message: 'Pedido creado correctamente', order })
}

export const getUserOrders = async (req, res) => {
  const { data, error } = await supabase
    .from('orders')
    .select(`
      *,
      order_items (
        *,
        products ( name, image_url, brand )
      )
    `)
    .eq('user_id', req.user.id)
    .order('created_at', { ascending: false })

  if (error) return res.status(500).json({ error: error.message })
  res.json(data)
}

export const getAllOrders = async (req, res) => {
  // Usamos RPC para bypasear RLS y obtener todos los pedidos
  const { data: orders, error: ordersError } = await supabase
    .rpc('get_all_orders')

  if (ordersError) return res.status(500).json({ error: ordersError.message })

  // Recuperamos los items de cada pedido
  const ordersWithItems = await Promise.all(
    orders.map(async order => {
      const { data: items } = await supabase
        .from('order_items')
        .select('*, products(name, image_url, brand)')
        .eq('order_id', order.id)

      return { ...order, order_items: items || [] }
    })
  )

  res.json(ordersWithItems)
}

export const updateOrderStatus = async (req, res) => {
  const { id }     = req.params
  const { status } = req.body

  const validStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled']
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Estado no válido' })
  }

  const { data, error } = await supabase.rpc('update_order_status', {
    p_order_id: id,
    p_status:   status
  })

  if (error) return res.status(500).json({ error: error.message })
  if (!data)  return res.status(404).json({ error: 'Pedido no encontrado' })

  res.json(data)
}