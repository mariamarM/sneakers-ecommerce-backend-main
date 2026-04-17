export const adminMiddleware = (req, res, next) => {
  const role = req.user?.user_metadata?.role

  if (role !== 'admin') {
    return res.status(403).json({ error: 'Acceso restringido a administradores' })
  }

  next()
}