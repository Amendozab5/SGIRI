import { Directive, ElementRef, AfterViewInit, OnDestroy, HostListener, Input } from '@angular/core';
import { Dropdown } from 'bootstrap';

@Directive({
  selector: '[appBootstrapDropdown]',
  standalone: true
})
export class BootstrapDropdownDirective implements AfterViewInit, OnDestroy {
  private bsDropdown: Dropdown | undefined;

  // Optional: Input to control dropdown behavior or pass options
  @Input() public dropup: boolean = false;

  constructor(private el: ElementRef) { }

  ngAfterViewInit(): void {
    if (this.el.nativeElement) {
      const toggleElement = this.el.nativeElement.querySelector('.dropdown-toggle');
      if (toggleElement) {
        toggleElement.setAttribute('data-bs-toggle', 'dropdown'); // Ensure the attribute is set
        this.bsDropdown = new Dropdown(toggleElement); // Initialize on the toggle element
      }
    }
  }

  @HostListener('click', ['$event'])
  onClick(event: Event): void {
    const toggleElement = this.el.nativeElement.querySelector('.dropdown-toggle');
    if (event.target && toggleElement && toggleElement.contains(event.target as Node)) {
        this.bsDropdown?.toggle(); // Explicitly toggle the dropdown
    }
  }

  ngOnDestroy(): void {
    if (this.bsDropdown) {
      this.bsDropdown.dispose();
      this.bsDropdown = undefined;
    }
  }
}
