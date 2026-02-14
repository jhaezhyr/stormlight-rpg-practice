#!/usr/bin/env node
const WebSocket = require('ws');
const { spawn } = require('child_process');
const path = require('path');

const WS_PORT = process.env.WS_PORT || 4000;

function spawnServer(cmd, args) {
    const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    p.stdout.on('data', d => process.stdout.write(`[server] ${d}`));
    p.stderr.on('data', d => process.stderr.write(`[server] ${d}`));
    p.on('error', (err) => console.warn('[server] child error', err && err.message));
    return p;
}

async function run() {
    // Start ws test server if not already running
    let wsProc = null;
    try {
        const ws = new WebSocket(`ws://localhost:${WS_PORT}`);
        await new Promise((res, rej) => {
            const t = setTimeout(() => { ws.terminate(); res(false); }, 200);
            ws.on('open', () => { clearTimeout(t); ws.close(); res(true); });
            ws.on('error', () => { clearTimeout(t); res(false); });
        });
    } catch (e) {
        // not running
    }

    // spawn a server regardless to ensure behavior
    wsProc = spawnServer('node', [path.join(__dirname, 'ws-test-server.js')]);

    await new Promise(r => setTimeout(r, 400));

    const client = new WebSocket(`ws://localhost:${WS_PORT}`);
    const received = [];

    client.on('message', (data) => {
        try {
            const msg = JSON.parse(data.toString());
            received.push(msg);
            // when prompt arrives, send answer
            if (msg.type === 'prompt') {
                client.send(JSON.stringify({ type: 'answer', message: 'integration-attack' }));
            }
            // when we see acknowledgment, finish
            if (msg.type === 'event' && msg.message && msg.message.includes('You answered:')) {
                console.log('Integration test succeeded');
                client.close();
                if (wsProc) wsProc.kill();
                process.exit(0);
            }
        } catch (e) {
            console.warn('Invalid JSON from server', e);
        }
    });

    client.on('open', () => console.log('Integration client connected'));
    client.on('error', (err) => {
        console.error('Client error', err && err.message);
        if (wsProc) wsProc.kill();
        process.exit(2);
    });

    // timeout failure
    setTimeout(() => {
        console.error('Integration test timed out', received);
        if (wsProc) wsProc.kill();
        process.exit(3);
    }, 10000);
}

run();
