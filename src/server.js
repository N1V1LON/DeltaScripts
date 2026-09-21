const http = require('http');
const fs = require('fs');
const path = require('path');
const WebSocket = require('ws');
const { createRobloxEnvironment } = require('./roblox_env');

const PORT = process.env.PORT || 3000;
const WEB_ROOT = path.join(__dirname, '..', 'web');

let robloxEnv = null;
const clients = new Set();

function broadcastTree() {
	if (!robloxEnv) return;
	try {
		const tree = robloxEnv.getTreeState();
		const msg = JSON.stringify({ type: 'tree_update', data: tree });
		for (const client of clients) {
			if (client.readyState === WebSocket.OPEN) {
				client.send(msg);
			}
		}
	} catch (err) {
		console.error('[Server] Error broadcasting tree:', err);
	}
}

function initEnv() {
	robloxEnv = createRobloxEnvironment((event) => {
		broadcastTree();
	});

	const mainScriptPath = path.join(__dirname, '..', 'Scripts', 'ControlerScript.lua');
	if (fs.existsSync(mainScriptPath)) {
		console.log('[Server] Loading ControlerScript.lua...');
		const luaCode = fs.readFileSync(mainScriptPath, 'utf8');
		try {
			robloxEnv.execute(luaCode, 'ControlerScript.lua');
			console.log('[Server] ControlerScript.lua loaded successfully!');
		} catch (e) {
			console.error('[Server] Error running ControlerScript.lua:', e);
		}
	} else {
		console.warn('[Server] Scripts/ControlerScript.lua not found');
	}
}

const server = http.createServer((req, res) => {
	const reqPath = req.url === '/' ? '/index.html' : req.url;
	const safePath = path.normalize(reqPath).replace(/^(\.\.[\/\\])+/, '');
	const filePath = path.join(WEB_ROOT, safePath);

	if (!filePath.startsWith(WEB_ROOT)) {
		res.writeHead(403, { 'Content-Type': 'text/html' });
		res.end('<h1>403 Forbidden</h1>', 'utf-8');
		return;
	}

	const extname = String(path.extname(filePath)).toLowerCase();
	const mimeTypes = {
		'.html': 'text/html',
		'.js': 'text/javascript',
		'.css': 'text/css',
		'.json': 'application/json',
		'.png': 'image/png',
		'.jpg': 'image/jpg'
	};

	const contentType = mimeTypes[extname] || 'application/octet-stream';

	fs.readFile(filePath, (error, content) => {
		if (error) {
			if (error.code === 'ENOENT') {
				res.writeHead(404, { 'Content-Type': 'text/html' });
				res.end('<h1>404 Not Found</h1>', 'utf-8');
			} else {
				res.writeHead(500);
				res.end('Server Error: ' + error.code, 'utf-8');
			}
		} else {
			res.writeHead(200, { 'Content-Type': contentType });
			res.end(content, 'utf-8');
		}
	});
});

const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
	clients.add(ws);
	console.log('[Server] Web Client connected');

	if (robloxEnv) {
		ws.send(JSON.stringify({ type: 'tree_update', data: robloxEnv.getTreeState() }));
	}

	ws.on('message', (message) => {
		try {
			const data = JSON.parse(message);
			if (data.action === 'fire_event') {
				robloxEnv.triggerEvent(data.id, data.eventName, data.eventData);
				broadcastTree();
			} else if (data.action === 'update_property') {
				robloxEnv.updateProperty(data.id, data.key, data.value);
				broadcastTree();
			} else if (data.action === 'reload_scripts') {
				initEnv();
				broadcastTree();
			}
		} catch (err) {
			console.error('[Server] Error handling WS message:', err);
		}
	});

	ws.on('close', () => {
		clients.delete(ws);
		console.log('[Server] Web Client disconnected');
	});
});

initEnv();

server.listen(PORT, () => {
	console.log(`====================================================`);
	console.log(` Roblox UI to WebUI Engine running on http://localhost:${PORT}`);
	console.log(` Cross-platform: AMD64/ARM (Windows/Linux/Termux)`);
	console.log(`====================================================`);
});
