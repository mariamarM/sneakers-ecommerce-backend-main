import { createClient } from '@supabase/supabase-js'
import 'dotenv/config'

const supabaseUrl = process.env.SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Faltan variables de entorno de Supabase. Revisa tu archivo .env')
}

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: false,
    persistSession:   false
  },
  db: {
    schema: 'public'
  },
  global: {
    headers: {
      // Forzamos el rol service_role en cada petición
      'X-Client-Info': 'supabase-js-node'
    }
  }
})