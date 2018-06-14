// Bootstrap UI fixes after upgrading to Angular 1.3
app.directive('tooltip', function() {
    return {
        restrict: 'EA',
        link: function(scope, element, attrs) {
            attrs.tooltipPlacement = attrs.tooltipPlacement || 'top';
            attrs.tooltipAnimation = attrs.tooltipAnimation || true;
            attrs.tooltipPopupDelay = attrs.tooltipPopupDelay || 0;
            attrs.tooltipTrigger = attrs.tooltipTrigger || 'mouseenter';
            attrs.tooltipAppendToBody = attrs.tooltipAppendToBody || false;
        }
    }
})

app.directive('popover', function() {
    return {
        restrict: 'EA',
        link: function(scope, element, attrs) {
            attrs.popoverPlacement = attrs.popoverPlacement || 'top';
            attrs.popoverAnimation = attrs.popoverAnimation || true;
            attrs.popoverPopupDelay = attrs.popoverPopupDelay || 0;
            attrs.popoverTrigger = attrs.popoverTrigger || 'mouseenter';
            attrs.popoverAppendToBody = attrs.popoverAppendToBody || false;
        }
    }
})