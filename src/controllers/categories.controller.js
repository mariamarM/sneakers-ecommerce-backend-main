import { supabase } from '../config/supabase.js'

export const getCategories = async (req, res) => {
  const { data, error } = await supabase
    .from('categories')
    .select('*')
    .order('name')

  if (error) return res.status(500).json({ error: error.message })
  res.json(data)
}

export const createCategory = async (req, res) => {
  const { name, description } = req.body

  if (!name) return res.status(400).json({ error: 'El nombre es obligatorio' })

  const slug = name.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '')

  const { data, error } = await supabase
    .from('categories')
    .insert({ name, slug, description })
    .select()
    .single()

  if (error) return res.status(500).json({ error: error.message })
  res.status(201).json(data)
}