import { supabase } from '../config/supabase.js'

export const register = async (req, res) => {
  const { email, password, full_name } = req.body

  if (!email || !password || !full_name) {
    return res.status(400).json({ error: 'Email, contraseña y nombre son obligatorios' })
  }

  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password,
    user_metadata: { full_name, role: 'user' },
    email_confirm: true
  })

  if (error) return res.status(400).json({ error: error.message })
  res.status(201).json({ message: 'Usuario creado correctamente', user: data.user })
}

export const login = async (req, res) => {
  const { email, password } = req.body

  if (!email || !password) {
    return res.status(400).json({ error: 'Email y contraseña son obligatorios' })
  }

  const { data, error } = await supabase.auth.signInWithPassword({ email, password })

  if (error) return res.status(401).json({ error: 'Credenciales incorrectas' })
  res.json({
    access_token:  data.session.access_token,
    refresh_token: data.session.refresh_token,
    user: {
      id:        data.user.id,
      email:     data.user.email,
      full_name: data.user.user_metadata.full_name,
      role:      data.user.user_metadata.role
    }
  })
}

export const getProfile = async (req, res) => {
  res.json({
    id:        req.user.id,
    email:     req.user.email,
    full_name: req.user.user_metadata.full_name,
    role:      req.user.user_metadata.role
  })
}