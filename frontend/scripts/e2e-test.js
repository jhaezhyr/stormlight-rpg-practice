#!/usr/bin/env node
const { spawn } = require('child_process');
const net = require('net');
const path = require('path');
const puppeteer = require('puppeteer');

const WS_PORT = process.env.WS_PORT || 4000;
const SERVE_PORT = process.env.SERVE_PORT || 4201;

function spawnServer(cmd, args, opts = {}) {
    const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'], ...opts });
    p.stdout.on('data', d => process.stdout.write(`[server] ${d}`));
    p.stderr.on('data', d => process.stderr.write(`[server] ${d}`));
    p.on('error', (err) => console.warn('[server] child error', err && err.message));
    return p;
}

(async () => {
    // Start or reuse ws test server
    let wsProc = null;
    const isWsRunning = await new Promise((res) => {
        const s = net.createConnection({ port: WS_PORT }, () => { s.end(); res(true); });
        s.on('error', () => res(false));
    });
    if (!isWsRunning) {
        wsProc = spawnServer('node', [path.join(__dirname, 'ws-test-server.js')]);
        // give it time to start
        await new Promise(r => setTimeout(r, 800));
    } else {
        console.log(`Reusing existing WS server on port ${WS_PORT}`);
    }

    // Start or reuse static server
    let serveProc = null;
    const isServeRunning = await new Promise((res) => {
        const s = net.createConnection({ port: SERVE_PORT }, () => { s.end(); res(true); });
        s.on('error', () => res(false));
    });
    if (!isServeRunning) {
        serveProc = spawnServer('node', [path.join(__dirname, 'serve-dist.js')]);
        await new Promise(r => setTimeout(r, 600));
    } else {
        console.log(`Reusing existing static server on port ${SERVE_PORT}`);
    }

    // Allow using an existing Chrome/Chromium by setting PUPPETEER_EXECUTABLE_PATH
    const executablePath = process.env.PUPPETEER_EXECUTABLE_PATH || process.env.CHROME_PATH || undefined;
    try {
        const launchOpts = {
            headless: 'new',
            args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
        };
        if (executablePath) launchOpts.executablePath = executablePath;
        const browser = await puppeteer.launch(launchOpts);
        const page = await browser.newPage();
        page.setDefaultTimeout(30000);

        const url = `http://localhost:${SERVE_PORT}`;
        console.log('Opening', url);
        await page.goto(url);

        // Fill websocket URL input and click Connect (use robust selectors)
        await page.waitForSelector('.toolbar input', { timeout: 30000 });
        await page.focus('.toolbar input');
        await page.keyboard.type(`ws://localhost:${WS_PORT}`);
        // find a button with text 'Connect' and click it
        const [connectBtn] = await page.$x("//button[contains(normalize-space(.), 'Connect')]");
        if (connectBtn) {
            await connectBtn.click();
        } else {
            throw new Error('Connect button not found');
        }

        // Wait for the prompt text from the test server ("What do you do?")
        await page.waitForFunction(() => {
            const el = document.querySelector('.prompt-area .prompt-message .text');
            return el && el.textContent && el.textContent.includes('What do you do?');
        }, { timeout: 10000 });

        // Type an answer and submit
        await page.focus('.prompt-area input[type="text"]');
        await page.keyboard.type('attack');
        await page.click('.prompt-area button[type="submit"]');

        // Wait for acknowledgment in event log
        await page.waitForFunction(() => {
            const items = Array.from(document.querySelectorAll('.event-log ul li .msg-text'));
            return items.some(i => i.textContent && i.textContent.includes('You answered: attack'));
        }, { timeout: 5000 });

        console.log('E2E test passed');

        await browser.close();
        if (wsProc) wsProc.kill();
        if (serveProc) serveProc.kill();
        process.exit(0);
    } catch (err) {
        console.error('E2E browser run failed:', err && err.message ? err.message : err);
        console.error('If Chromium fails to launch on this machine, set PUPPETEER_EXECUTABLE_PATH to a local Chrome/Chromium binary and re-run.');
        if (wsProc) wsProc.kill();
        if (serveProc) serveProc.kill();
        process.exit(2);
    }
})().catch(err => {
    console.error('E2E test failed', err);
    process.exit(1);
});
