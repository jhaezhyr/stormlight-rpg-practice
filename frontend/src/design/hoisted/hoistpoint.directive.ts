import { AfterViewInit, Directive, ElementRef, OnDestroy, ViewContainerRef } from "@angular/core";
import { HoistedDirective } from "./hoisted.directive";
import { zip } from "../../lib/iterables";

/**
 * Used to implement the {@link HoistedDirective}.
 */
@Directive({
    selector: '[myHoistPoint]',
    host: {
        '[style.position]': '"relative"'
    }
})
export class HoistPointDirective implements AfterViewInit, OnDestroy {
    constructor(
        private readonly element: ElementRef<HTMLElement>,
        private readonly viewContainer: ViewContainerRef
    ) { }
    private hoistedElements: Array<HoistedDirective> = []
    private positioningCallback: number | undefined;
    public addHoistedElement(newHoistedElement: HoistedDirective) {
        this.hoistedElements.push(newHoistedElement);
    }

    public ngAfterViewInit(): void {
        const map: [HTMLElement, HTMLElement][] = [];
        for (const hoisted of this.hoistedElements) {
            const embeddedView = this.viewContainer.createEmbeddedView(hoisted.templateRef);
            const hoistedNodes = embeddedView.rootNodes;
            for (const [hoistedNode, spacerNode] of zip(hoistedNodes, hoisted.renderedElements)) {
                if (hoistedNode instanceof HTMLElement) {
                    this.element.nativeElement.appendChild(hoistedNode);
                    map.push([hoistedNode, spacerNode])
                }
            }
        }
        if (this.positioningCallback !== undefined) {
            cancelAnimationFrame(this.positioningCallback);
        }
        const positionAndSchedule = () => {
            for (const [hoisted, spacer] of map) {
                this.positionHoistedNode(hoisted, spacer)
            }
            const callback = requestAnimationFrame(() => {
                positionAndSchedule();
            });
            this.positioningCallback = callback;
        }
        positionAndSchedule();
    }

    public ngOnDestroy(): void {
        if (this.positioningCallback !== undefined) {
            cancelAnimationFrame(this.positioningCallback);
        }
    }

    public positionHoistedNode(hoistedNode: HTMLElement, spacerNode: HTMLElement) {
        const spacerBounds = spacerNode.getBoundingClientRect();
        const myBounds = this.element.nativeElement.getBoundingClientRect();
        hoistedNode.style.position = "absolute";
        hoistedNode.style.boxSizing = "border-box";
        hoistedNode.style.left = `${spacerBounds.left - myBounds.left}px`;
        hoistedNode.style.top = `${spacerBounds.top - myBounds.top}px`;
        hoistedNode.style.width = `${spacerBounds.width}px`;
        hoistedNode.style.height = `${spacerBounds.height}px`;
    }
}