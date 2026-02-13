import { Injectable } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { GameMessageBase } from '../models/game-message.model';

@Injectable({ providedIn: 'root' })
export class GameSocketService {
    private ws: WebSocket | null = null;
    private messagesSubject = new Subject<GameMessageBase>();
    public messages$ = this.messagesSubject.asObservable();

    connect(url: string) {
        if (this.ws) {
            this.ws.close();
        }
        this.ws = new WebSocket(url);

        this.ws.addEventListener('open', () => {
            console.info('WebSocket connected', url);
        });

        this.ws.addEventListener('message', (ev) => {
            try {
                const data = JSON.parse(ev.data) as GameMessageBase;
                this.messagesSubject.next(data);
            } catch (err) {
                console.warn('Failed to parse WS message', err);
            }
        });

        this.ws.addEventListener('close', () => {
            console.info('WebSocket closed');
        });

        this.ws.addEventListener('error', (e) => {
            console.error('WebSocket error', e);
        });
    }

    sendMessage(answer: string) {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
            console.warn('WebSocket not open; cannot send message');
            return;
        }
        const payload = JSON.stringify({ type: 'answer', message: answer });
        this.ws.send(payload);
    }

    disconnect() {
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
    }
}
