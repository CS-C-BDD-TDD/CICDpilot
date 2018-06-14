app.service('Gfi', ['$rootScope', function ($rootScope) {
    return {
        showGFIs: function () {
            return $rootScope.setting_value('CLASSIFICATION');
        },
        get_new_gfi: function () {
            return {
                gfi_source_name: '',
                gfi_action_name: '',
                gfi_action_name_class: '',
                gfi_action_name_subclass: '',
                gfi_ps_regex: '',
                gfi_ps_regex_class: '',
                gfi_ps_regex_subclass: '',
                gfi_cs_regex: '',
                gfi_cs_regex_class: '',
                gfi_cs_regex_subclass: '',
                gfi_exp_sig_loc: '',
                gfi_exp_sig_loc_class: '',
                gfi_exp_sig_loc_subclass: '',
                gfi_bluesmoke_id: '',
                gfi_uscert_sid: '',
                gfi_notes: '',
                gfi_notes_class: '',
                gfi_notes_subclass: '',
                gfi_status: '',
                gfi_uscert_doc: '',
                gfi_uscert_doc_class: '',
                gfi_uscert_doc_subclass: '',
                gfi_special_inst: '',
                gfi_special_inst_class: '',
                gfi_special_inst_subclass: '',
                gfi_type: ''
            };
        },
        init_gfi_edit: function (scope, cyboxObject) {
            if (angular.isDefined(cyboxObject) && angular.isDefined(scope)) {
                if (this.showGFIs()) {
                    scope.gfiScope = {};
                    if (angular.isUndefined(cyboxObject.gfi) ||
                        cyboxObject.gfi === null) {
                        cyboxObject.gfi = this.get_new_gfi();
                    }
                    scope.showGFIs = true;
                }
                else {
                    scope.showGFIs = false;
                }
            }
        },
        set_gfi_attributes: function (cyboxObject) {
            if (this.showGFIs() && angular.isDefined(cyboxObject) &&
                angular.isDefined(cyboxObject.gfi)) {
                cyboxObject.gfi_attributes = cyboxObject.gfi;
            }
        },
        set_errors_on_gfiable_observables: function (scope, errors) {
            if (angular.isDefined(errors) && angular.isDefined(scope)) {
                scope.error = errors;
                if (this.showGFIs() && angular.isDefined(scope.gfiScope)) {
                    scope.gfiScope.error = errors;
                }
            }
        },
        delete_errors_on_gfiable_observables: function (scope) {
            if (angular.isDefined(scope) && angular.isDefined(scope.error)) {
                delete scope.error;
                if (this.showGFIs() && angular.isDefined(scope.gfiScope)) {
                    delete $scope.gfiScope.error;
                }
            }
        }
    };
}]);