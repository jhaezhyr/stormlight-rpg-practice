import { describe, it, expect, beforeEach } from 'vitest';
import { Subject } from 'rxjs';
import { GameStateService } from './game-state.service';
import { GameMessageBase } from '../models/game-message.model';

describe('GameStateService', () => {
    let messages$: Subject<GameMessageBase>;
    let mockSocket: any;
    let service: GameStateService;

    beforeEach(() => {
        messages$ = new Subject<GameMessageBase>();
        const sent: any[] = [];
        mockSocket = {
            messages$: messages$.asObservable(),
            connect: (_url: string) => { },
            disconnect: () => { },
            sendMessage: (m: string) => sent.push(m),
            _sent: sent,
        };

        service = new GameStateService(mockSocket);
        service.connect('ws://example');
    });

    it('handles event messages by prepending to event log and updating interface', () => {
        messages$.next({ type: 'event', message: 'an event', interface: { health: 42 } });
        expect(service.eventLog$.value.length).toBe(1);
        expect(service.eventLog$.value[0].message).toBe('an event');
        expect(service.playerInterface$.value.health).toBe(42);
    });

    it('handles hint by setting currentPromptOrHint and locking input', () => {
        messages$.next({ type: 'hint', message: 'a hint', interface: { weapons: ['knife'] } });
        expect(service.currentPromptOrHint$.value?.message).toBe('a hint');
        expect(service.isInputLocked$.value).toBe(true);
        expect(service.playerInterface$.value.weapons).toEqual(['knife']);
    });

    it('handles prompt by setting prompt and unlocking input', () => {
        messages$.next({ type: 'prompt', message: 'a prompt' });
        expect(service.currentPromptOrHint$.value?.message).toBe('a prompt');
        expect(service.isInputLocked$.value).toBe(false);
    });

    it('sendAnswer locks input and forwards message to socket', () => {
        service.sendAnswer('my answer');
        // socket mock records sent messages in _sent
        expect(mockSocket._sent.includes('my answer')).toBe(true);
        expect(service.isInputLocked$.value).toBe(true);
    });
});
