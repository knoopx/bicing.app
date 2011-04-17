$(function() {
    navigator.geolocation.getCurrentPosition(function(position) {
        $.getJSON("stations.json", {longitude: position.coords.longitude, latitude: position.coords.latitude }, function(response) {
            console.log(response);
        });
    }, function() {
    }, { enableHighAccuracy:true,maximumAge:600000 });
});