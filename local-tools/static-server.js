const http = require('http')
const fs = require('fs')
const path = require('path')

const root = path.resolve(__dirname, '..', 'public')
const port = Number(process.env.PORT || 4000)

const types = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.xml': 'application/xml; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
}

function resolveFile (urlPath) {
  const decoded = decodeURIComponent(urlPath.split('?')[0])
  const clean = path.normalize(decoded).replace(/^(\.\.[/\\])+/, '')
  let file = path.join(root, clean)
  if (!file.startsWith(root)) return null
  if (fs.existsSync(file) && fs.statSync(file).isDirectory()) {
    file = path.join(file, 'index.html')
  }
  if (!fs.existsSync(file)) {
    file = path.join(root, clean, 'index.html')
  }
  return fs.existsSync(file) ? file : null
}

http.createServer((req, res) => {
  const file = resolveFile(req.url || '/')
  if (!file) {
    res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' })
    res.end('Not found')
    return
  }

  res.writeHead(200, { 'content-type': types[path.extname(file).toLowerCase()] || 'application/octet-stream' })
  fs.createReadStream(file).pipe(res)
}).listen(port, () => {
  console.log(`Static preview: http://localhost:${port}`)
})
