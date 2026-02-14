import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GameStateService } from '../../services/game-state.service';

@Component({
    standalone: true,
    selector: 'app-event-log',
    imports: [CommonModule],
    templateUrl: './event-log.component.html',
    styleUrls: ['./event-log.component.scss'],
})
export class EventLogComponent {
    constructor(public state: GameStateService) { }
}
