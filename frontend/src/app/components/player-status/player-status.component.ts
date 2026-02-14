import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GameStateService } from '../../services/game-state.service';

@Component({
    standalone: true,
    selector: 'app-player-status',
    imports: [CommonModule],
    templateUrl: './player-status.component.html',
    styleUrls: ['./player-status.component.scss'],
})
export class PlayerStatusComponent {
    constructor(public state: GameStateService) { }
}
