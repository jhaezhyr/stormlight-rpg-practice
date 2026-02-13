#!/usr/bin/env node
const WebSocket = require('ws');
const port = process.env.PORT || 4000;
const wss = new WebSocket.Server({ port });

console.log(`WebSocket test server listening on ws://localhost:${port}`);

wss.on('connection', (ws) => {
    console.log('Client connected');

    // send initial interface
    ws.send(JSON.stringify({ type: 'event', message: 'Welcome to the test server', interface: { health: 100, weapons: ['sword'] } }));

    // send a hint after 1s
    setTimeout(() => {
        ws.send(JSON.stringify({ type: 'hint', message: 'A faint whisper says: go north', interface: { health: 98 } }));
    }, 1000);

    // send a prompt after 2s
    setTimeout(() => {
        ws.send(JSON.stringify({ type: 'prompt', message: 'What do you do?', interface: { health: 98 } }));
    }, 2000);

    ws.on('message', (data) => {
        try {
            const obj = JSON.parse(data);
            console.log('Received from client:', obj);
            if (obj.type === 'answer') {
                // respond with event acknowledging answer
                ws.send(JSON.stringify({ type: 'event', message: `You answered: ${obj.message}`, interface: { lastAnswer: obj.message } }));
                // also send a new prompt shortly
                setTimeout(() => {
                    ws.send(JSON.stringify({ type: 'prompt', message: 'Another question: pick A or B', interface: {} }));
                }, 800);
            }
        } catch (e) {
            console.warn('Invalid message from client', data.toString());
        }
    });

    ws.on('close', () => console.log('Client disconnected'));
});
