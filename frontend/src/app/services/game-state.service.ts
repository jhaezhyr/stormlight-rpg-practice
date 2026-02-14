import { Injectable } from '@angular/core';
import { BehaviorSubject, Subscription } from 'rxjs';
import { GameSocketService } from './game-socket.service';
import {
    GameMessageBase,
    EventMessage,
    HintMessage,
    PromptMessage,
    InterfaceData,
} from '../models/game-message.model';

@Injectable({ providedIn: 'root' })
export class GameStateService {
    public playerInterface$ = new BehaviorSubject<InterfaceData>("");
    public currentPromptOrHint$ = new BehaviorSubject<GameMessageBase | null>(null);
    public eventLog$ = new BehaviorSubject<EventMessage[]>([]);
    public isInputLocked$ = new BehaviorSubject<boolean>(true);

    private socketSub: Subscription | null = null;

    constructor(private socket: GameSocketService) { }

    connect(url: string) {
        this.socket.connect(url);
        this.socketSub = this.socket.messages$.subscribe((msg) => this.handleMessage(msg));
    }

    disconnect() {
        this.socket.disconnect();
        this.socketSub?.unsubscribe();
        this.socketSub = null;
    }

    sendAnswer(answer: string) {
        this.isInputLocked$.next(true);
        this.socket.sendMessage('answer', answer);
    }

    sendSkip() {
        this.socket.sendMessage('skip', 'plz');
    }

    private handleMessage(msg: GameMessageBase) {
        if (msg.interface) {
            this.playerInterface$.next(msg.interface);
        }

        switch (msg.type) {
            case 'event':
                this.prependEvent(msg as EventMessage);
                this.currentPromptOrHint$.next(msg as EventMessage)
                break;
            case 'hint':
                this.currentPromptOrHint$.next(msg as HintMessage);
                // keep input locked on hints
                this.isInputLocked$.next(true);
                break;
            case 'prompt':
                this.currentPromptOrHint$.next(msg as PromptMessage);
                this.isInputLocked$.next(false);
                break;
        }
    }

    private prependEvent(ev: EventMessage) {
        const current = this.eventLog$.value.slice();
        current.unshift(ev);
        this.eventLog$.next(current);
    }
}
