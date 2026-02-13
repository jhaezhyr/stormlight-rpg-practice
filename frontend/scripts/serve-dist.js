#!/usr/bin/env node
const express = require('express');
const path = require('path');

const port = process.env.PORT || 4201;
const app = express();

// Angular build puts the actual browser assets in `dist/stormlight-frontend/browser`
const distPath = path.join(__dirname, '..', 'dist', 'stormlight-frontend', 'browser');
app.use(express.static(distPath));

app.get('*', (req, res) => {
    res.sendFile(path.join(distPath, 'index.html'));
});

const server = app.listen(port, () => {
    console.log(`Serving dist at http://localhost:${port}`);
});

// Graceful shutdown
process.on('SIGINT', () => server.close(() => process.exit(0)));
process.on('SIGTERM', () => server.close(() => process.exit(0)));
