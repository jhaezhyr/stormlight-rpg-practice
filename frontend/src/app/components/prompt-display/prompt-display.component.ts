import { Component, ElementRef, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { GameStateService } from '../../services/game-state.service';

@Component({
    standalone: true,
    selector: 'app-prompt-display',
    imports: [CommonModule, FormsModule],
    templateUrl: './prompt-display.component.html',
    styleUrls: ['./prompt-display.component.scss'],
})
export class PromptDisplayComponent {
    @ViewChild('answerInput', { static: true }) answerInput!: ElementRef<HTMLInputElement>;
    public answer = '';

    constructor(public state: GameStateService) { }

    onSubmit(ev: Event) {
        ev.preventDefault();
        if (!this.answer?.trim()) return;
        this.state.sendAnswer(this.answer.trim());
        this.answer = '';
        requestAnimationFrame(() => this.answerInput.nativeElement.focus());
    }
}
