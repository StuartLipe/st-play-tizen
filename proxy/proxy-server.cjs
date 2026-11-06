/* Proxy server for ST PLAY - Versao restaurada (sem caps agressivos de catalogo) */
'use strict';

const http = require('http');
const url = require('url');

const PORT = 80;

function sendJson(res, data, statusCode = 200) {
  const body = Buffer.from(JSON.stringify(data));
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': body.length,
    'Access-Control-Allow-Origin': '*',
  });
  res.end(body);
}

function proxyRequest(req, res, targetUrl) {
  const parsed = url.parse(targetUrl);
  const options = {
    hostname: parsed.hostname,
    port: parsed.port || 80,
    path: parsed.path || '/',
    method: req.method,
    headers: { ...req.headers, 'Accept-Encoding': 'identity' },
  };

  const proxyReq = http.request(options, (upRes) => {
    const contentType = upRes.headers['content-type'] || '';
    const statusCode = upRes.statusCode;
    
    res.writeHead(statusCode, {
      'Content-Type': contentType || 'application/json',
      'Access-Control-Allow-Origin': '*',
    });

    upRes.pipe(res);
  });

  proxyReq.on('error', (e) => {
    sendJson(res, { error: 'upstream error: ' + e.message });
  });

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    req.pipe(proxyReq);
  } else {
    proxyReq.end();
  }
}

function handle(req, res) {
  const parsedUrl = url.parse(req.url, true);
  const target = parsedUrl.query.url || '';

  // API de categorias - sem limite agressivo
  if (target.includes('player_api.php') && target.includes('action=get_vod_categories')) {
    proxyRequest(req, res, 'http://gmaster1.shop/player_api.php?' + 
      Object.keys(req.query).filter(k => k !== 'url').map(k => k + '=' + req.query[k]).join('&'));
    return;
  }

  // API de VOD - encaminhar normalmente (sem truncamento agressivo)
  if (target.includes('player_api.php') && target.includes('action=get_vod_streams')) {
    proxyRequest(req, res, 'http://gmaster1.shop/player_api.php?' + 
      Object.keys(req.query).filter(k => k !== 'url').map(k => k + '=' + req.query[k]).join('&'));
    return;
  }

  // API de series - sem limite
  if (target.includes('player_api.php') && target.includes('action=get_series')) {
    proxyRequest(req, res, 'http://gmaster1.shop/player_api.php?' + 
      Object.keys(req.query).filter(k => k !== 'url').map(k => k + '=' + req.query[k]).join('&'));
    return;
  }

  // API de live - sem limite
  if (target.includes('player_api.php') && target.includes('action=get_live_streams')) {
    proxyRequest(req, res, 'http://gmaster1.shop/player_api.php?' + 
      Object.keys(req.query).filter(k => k !== 'url').map(k => k + '=' + req.query[k]).join('&'));
    return;
  }

  // API de categorias de live
  if (target.includes('player_api.php') && target.includes('action=get_live_categories')) {
    proxyRequest(req, res, 'http://gmaster1.shop/player_api.php?' + 
      Object.keys(req.query).filter(k => k !== 'url').map(k => k + '=' + req.query[k]).join('&'));
    return;
  }

  // Fallback: encaminhar para o proxy normal
  const base = 'http://192.168.100.196/proxy';
  const targetUrl = base + '?url=' + encodeURIComponent(req.url);
  proxyRequest(req, res, targetUrl);
}

// Health check
if (req.url === '/health') {
  sendJson(res, { ok: true, port: PORT });
  return;
}

handle(req, res);
}

http.createServer(handle).listen(80, () => {
  console.log('Proxy running on port 80');
});