export type MessageType = 'event' | 'hint' | 'prompt';

export interface InterfaceData {
    health?: number;
    weapons?: string[];
    [key: string]: any;
}

export interface GameMessageBase {
    type: MessageType;
    message: string;
    interface?: InterfaceData;
}

export interface EventMessage extends GameMessageBase {
    type: 'event';
}

export interface HintMessage extends GameMessageBase {
    type: 'hint';
}

export interface PromptMessage extends GameMessageBase {
    type: 'prompt';
}
