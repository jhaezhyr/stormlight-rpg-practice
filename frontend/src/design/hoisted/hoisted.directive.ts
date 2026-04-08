import { Directive, Input, TemplateRef, ViewContainerRef, OnInit, EmbeddedViewRef } from "@angular/core";
import { HoistPointDirective } from "./hoistpoint.directive";

/**
 * Used to prevent any nested interactions, like buttons inside buttons.
 * 
 * The element that has this directive becomes a non-interactive spacer, where opacity is 0, pointer events are ignored, and no tab indices or aria roles exist. It is still fully functional, just not interactible by mouse, keyboard, screen-reader, etc. Then a second element is instantiated as a direct child of the nearest hoist-point ancestor. That second element is also fully functional, but is absolutely positioned over the top of the first element.
 * 
 * Warnings
 * - These two instantiations will be selected by different CSS selectors, and may therefore have different appearances.
 * - Doesn't work well with elements that can wrap, i.e. inline text. Make those into inline-blocks first.
 * 
 * Usage:
 * ```html
 * <my-accordion *ngFor="let person of changers" myHoistPoint>
 *   <my-heading [level]="3" my-accordion-heading>
 *     Changes made by
 *     <my-at-mention [person]="person" *myHoisted></my-at-mention>
 *   </my-heading>
 *   <my-changes [madeBy]="person" my-accordion-contents></my-changes>
 * </my-accordion>
 * ```
 */
@Directive({
    selector: '[myHoisted]'
})
export class HoistedDirective implements OnInit {
    public renderedElements!: Array<HTMLElement>
    constructor(
        public readonly templateRef: TemplateRef<unknown>, // Accesses the template content
        private readonly viewContainer: ViewContainerRef, // Manages rendering in the DOM
        private readonly hoistPoint: HoistPointDirective,
    ) { }

    public ngOnInit(): void {
        this.hoistPoint.addHoistedElement(this);
        const renderedView = this.viewContainer.createEmbeddedView(this.templateRef);
        this.renderedElements = renderedView.rootNodes as Array<HTMLElement>
        for (const node of this.renderedElements) {
            node.style.opacity = "0%";
            this.ghostify(node);
        }
    }

    private ghostify(element: HTMLElement) {
        if (element.tabIndex >= 0) {
            element.tabIndex = -1
        }
        element.style.pointerEvents = "none"
        element.role = "none";
        element.ariaHidden = "true";
        for (const desc of element.childNodes) {
            if (!(desc instanceof HTMLElement)) {
                continue;
            }
            this.ghostify(desc);
        }
    }
}