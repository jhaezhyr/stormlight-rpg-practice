import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PlayerStatusComponent } from '../player-status/player-status.component';
import { PromptDisplayComponent } from '../prompt-display/prompt-display.component';
import { EventLogComponent } from '../event-log/event-log.component';
import { GameStateService } from '../../services/game-state.service';

@Component({
    standalone: true,
    selector: 'app-game-container',
    imports: [CommonModule, FormsModule, PlayerStatusComponent, PromptDisplayComponent, EventLogComponent],
    templateUrl: './game-container.component.html',
    styleUrls: ['./game-container.component.scss'],
})
export class GameContainerComponent {
    public wsUrl = 'ws://localhost:4000';

    constructor(private state: GameStateService) { }

    connect() {
        if (!this.wsUrl) return;
        this.state.connect(this.wsUrl);
    }

    disconnect() {
        this.state.disconnect();
    }
}
