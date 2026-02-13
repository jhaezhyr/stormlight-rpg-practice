import { bootstrapApplication } from '@angular/platform-browser';
import { GameContainerComponent } from './app/components/game-container/game-container.component';

bootstrapApplication(GameContainerComponent).catch(err => console.error(err));
