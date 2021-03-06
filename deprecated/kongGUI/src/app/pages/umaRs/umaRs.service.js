(function () {
  'use strict';

  angular.module('KongGUI.pages.umaRs')
    .factory('umaRsService', umaRsService);

  /** @ngInject */
  function umaRsService($http, urls) {
    var service = {
      addPlugin: addPlugin,
      getScope: getScope
    };

    function addPlugin(api_id, formData, onSuccess, onError) {
      return $http.post(urls.KONG_NODE_API + '/api/apis/' + api_id + '/plugins', formData).then(onSuccess).catch(onError);
    }

    function getScope(onSuccess, onError) {
      return $http.get(urls.KONG_NODE_API + '/api/scopes').then(onSuccess).catch(onError);
    }

    return service;
  }
})();