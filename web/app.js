let socket = null;
const screenEl = document.getElementById('roblox-screen');
const wsStatus = document.getElementById('ws-status');
const reloadBtn = document.getElementById('reload-btn');

function connectWebSocket() {
	const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
	const wsUrl = `${protocol}//${window.location.host}`;

	socket = new WebSocket(wsUrl);

	socket.onopen = () => {
		wsStatus.textContent = 'Подключено';
		wsStatus.className = 'status-indicator connected';
	};

	socket.onmessage = (event) => {
		try {
			const msg = JSON.parse(event.data);
			if (msg.type === 'tree_update' && msg.data) {
				renderTree(msg.data);
			}
		} catch (e) {
			console.error('Error handling message:', e);
		}
	};

	socket.onclose = () => {
		wsStatus.textContent = 'Отключено';
		wsStatus.className = 'status-indicator disconnected';
		setTimeout(connectWebSocket, 2000);
	};

	socket.onerror = (err) => {
		console.error('WebSocket error:', err);
	};
}

function sendEvent(id, eventName, eventData = {}) {
	if (socket && socket.readyState === WebSocket.OPEN) {
		socket.send(JSON.stringify({
			action: 'fire_event',
			id: id,
			eventName: eventName,
			eventData: eventData
		}));
	}
}

function sendPropertyUpdate(id, key, value) {
	if (socket && socket.readyState === WebSocket.OPEN) {
		socket.send(JSON.stringify({
			action: 'update_property',
			id: id,
			key: key,
			value: value
		}));
	}
}

function renderTree(rootNode) {
	screenEl.innerHTML = '';
	if (!rootNode || !rootNode.children) return;

	const viewportW = screenEl.clientWidth || 800;
	const viewportH = screenEl.clientHeight || 600;

	for (const child of rootNode.children) {
		const el = createInstanceElement(child, viewportW, viewportH);
		if (el) {
			screenEl.appendChild(el);
		}
	}
}

function createInstanceElement(node, parentW, parentH) {
	if (!node || node.visible === false) return null;

	let el;
	const cls = node.className;

	if (cls === 'TextButton') {
		el = document.createElement('button');
		el.textContent = node.text || '';
	} else if (cls === 'TextLabel') {
		el = document.createElement('div');
		el.textContent = node.text || '';
	} else if (cls === 'TextBox') {
		el = document.createElement('input');
		el.type = 'text';
		el.value = node.text || '';
		el.placeholder = node.placeholderText || '';
	} else {
		el = document.createElement('div');
	}

	el.className = `rbx-instance rbx-${cls}`;
	el.dataset.id = node.id;

	let elemWidth = parentW;
	let elemHeight = parentH;

	if (cls === 'ScreenGui' || cls === 'Folder') {
		el.style.left = '0px';
		el.style.top = '0px';
		el.style.width = '100%';
		el.style.height = '100%';
		elemWidth = parentW;
		elemHeight = parentH;
	} else {
		// Calculate Position from UDim2
		if (node.position && node.position.x && node.position.y) {
			const left = (node.position.x.scale * parentW) + node.position.x.offset;
			const top = (node.position.y.scale * parentH) + node.position.y.offset;
			el.style.left = `${left}px`;
			el.style.top = `${top}px`;
		}

		// Calculate Size from UDim2
		if (node.size && node.size.x && node.size.y) {
			elemWidth = (node.size.x.scale * parentW) + node.size.x.offset;
			elemHeight = (node.size.y.scale * parentH) + node.size.y.offset;
			el.style.width = `${elemWidth}px`;
			el.style.height = `${elemHeight}px`;
		}
	}

	// Styles
	if (node.backgroundColor && cls !== 'Folder' && cls !== 'ScreenGui') {
		const c = node.backgroundColor;
		const alpha = 1 - (node.backgroundTransparency || 0);
		el.style.backgroundColor = `rgba(${c.r}, ${c.g}, ${c.b}, ${alpha})`;
	}

	if (node.textColor) {
		const tc = node.textColor;
		el.style.color = `rgb(${tc.r}, ${tc.g}, ${tc.b})`;
	}

	if (node.textSize) {
		el.style.fontSize = `${node.textSize}px`;
	}

	if (node.textXAlignment) {
		const alignMap = { 'Left': 'flex-start', 'Center': 'center', 'Right': 'flex-end' };
		el.style.justifyContent = alignMap[node.textXAlignment] || 'center';
	}

	if (node.cornerRadius && node.cornerRadius.offset > 0) {
		el.style.borderRadius = `${node.cornerRadius.offset}px`;
	}

	if (node.color && node.thickness > 0) {
		const sc = node.color;
		el.style.border = `${node.thickness}px solid rgb(${sc.r}, ${sc.g}, ${sc.b})`;
	}

	// Child UICorner / UIStroke overrides
	if (node.children) {
		for (const child of node.children) {
			if (child.className === 'UICorner' && child.cornerRadius) {
				const r = child.cornerRadius.offset || 0;
				el.style.borderRadius = `${r}px`;
			} else if (child.className === 'UIStroke') {
				const sc = child.color || { r: 0, g: 0, b: 0 };
				const thick = child.thickness || 1;
				el.style.border = `${thick}px solid rgb(${sc.r}, ${sc.g}, ${sc.b})`;
			}
		}
	}

	// Event Handlers
	let pressTimer = null;

	el.addEventListener('mousedown', (e) => {
		e.stopPropagation();
		sendEvent(node.id, 'InputBegan', { UserInputType: 'MouseButton1', Position: { X: e.clientX, Y: e.clientY } });

		pressTimer = setTimeout(() => {
			sendEvent(node.id, 'Hold', { UserInputType: 'MouseButton1' });
		}, 700);
	});

	el.addEventListener('mouseup', (e) => {
		e.stopPropagation();
		if (pressTimer) clearTimeout(pressTimer);
		sendEvent(node.id, 'InputEnded', { UserInputType: 'MouseButton1' });
	});

	if (cls === 'TextButton') {
		el.addEventListener('click', (e) => {
			e.stopPropagation();
			sendEvent(node.id, 'MouseButton1Click', {});
		});
	}

	if (cls === 'TextBox') {
		el.addEventListener('input', (e) => {
			sendPropertyUpdate(node.id, 'Text', e.target.value);
		});
	}

	// Render children recursively passing calculated pixel width and height
	if (node.children) {
		for (const child of node.children) {
			if (child.className !== 'UICorner' && child.className !== 'UIStroke') {
				const childEl = createInstanceElement(child, elemWidth, elemHeight);
				if (childEl) {
					el.appendChild(childEl);
				}
			}
		}
	}

	return el;
}

reloadBtn.addEventListener('click', () => {
	if (socket && socket.readyState === WebSocket.OPEN) {
		socket.send(JSON.stringify({ action: 'reload_scripts' }));
	}
});

connectWebSocket();
