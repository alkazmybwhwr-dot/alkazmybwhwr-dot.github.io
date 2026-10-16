(function(){
  var A="PUT-ONESIGNAL-APP-ID";
  if(A.indexOf("PUT")===0) return;
  window.OneSignalDeferred=window.OneSignalDeferred||[];
  var s=document.createElement("script");
  s.src="https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js"; s.defer=1; document.head.appendChild(s);
  OneSignalDeferred.push(function(O){ O.init({ appId:A, allowLocalhostAsSecureOrigin:true }); });
})();
