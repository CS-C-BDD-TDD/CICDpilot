// Adapted from http://plnkr.co/edit/DgE5eGGmGebQfWunhqqv?p=preview

app.directive('ngConfirmClick', ['$modal', function($modal) {
  var ModalInstanceCtrl = function($scope, $modalInstance) {
    $scope.ok = function() {
      $modalInstance.close();
    };

    $scope.cancel = function() {
      $modalInstance.dismiss('cancel');
    };
  };

  return {
    restrict: 'A',
    scope:{
      ngConfirmClick:"&",
      item:"="
    },
    link: function(scope, element, attrs) {
      element.bind('click', function() {
        var message = attrs.ngConfirmMessage || "Are you sure ?";

        var modalHtml = '<div class="modal-body">' + message + '</div>';
        modalHtml += '<div class="modal-footer"><button class="btn btn-primary" ng-click="ok()">OK</button><button class="btn btn-warning" ng-click="cancel()">Cancel</button></div>';

        var modalInstance = $modal.open({
          template: modalHtml,
          controller: ModalInstanceCtrl
        });

        modalInstance.result.then(function() {
          scope.ngConfirmClick({item:scope.item});
        }, function() {
          //Modal dismissed
        });
      });
    }
  }
}]);
