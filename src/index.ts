import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import process from 'process';

const app = new Hono()

app.get('/', (c) => {
  return c.text('Hello Hono!')
})

const port = Number(process.env.PORT || '7860');
console.log(`Server is running on http://localhost:${port}`)

serve({
  fetch: app.fetch,
  port
})
