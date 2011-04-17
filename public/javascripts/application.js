Bicing = new Ext.Application({
    name: "Bicing",
    launch: function() {
        Ext.regModel('Placemark', {
            fields: ['name', 'distance', 'latitude', 'longitude']
        });

        this.placemarksStore = new Ext.data.Store({
            model: 'Placemark',
            sorters: 'distance',
            data: []
        });

        this.placemarksList = new Ext.List({
            title: 'Estacions',
            itemTpl : '<div class="placemark">' +
                    '{name}' +
                    '<span class="distance">{distance}</span>' +
                    '</div>' +
                    '<div class="seats">' +
                    '<span class="open">{open}</span>' +
                    '<span class="closed">{closed}</span>' +
                    '</div>',
            indexBar: false,
            disableSelection: true,
            store: Bicing.placemarksStore,
            onItemDisclosure: function(record, button, index) {
                window.location = "http://maps.google.com/maps?q=" + record.data["latitude"] + "," + record.data["longitude"]
            }
        });

        this.refreshPlacemarks = function() {
            var loadingMask = new Ext.LoadMask(Ext.getBody(), {msg:"Please wait..."});
            loadingMask.show();

            navigator.geolocation.getCurrentPosition(function(position) {
                Ext.Ajax.request({
                    method: "GET",
                    url: "placemarks.json",
                    params: { longitude: position.coords.longitude, latitude: position.coords.latitude },
                    success: function(response) {
                        Bicing.placemarksStore.loadData(Ext.decode(response.responseText));
                        loadingMask.hide();
                    }
                });
            }, function() {
            }, { enableHighAccuracy:true,maximumAge:600000 });
        };

        this.viewport = new Ext.Panel({
            fullscreen: true,
            dockedItems: [
                {
                    xtype: 'toolbar',
                    ui: 'light',
                    dock: 'top',
                    title: 'Bicing',
                    defaults: {
                        iconMask: true,
                        ui: 'plain'
                    },
                    scroll: {
                        direction: 'horizontal',
                        useIndicators: false
                    },
                    layout: {
                        pack: 'right'
                    },
                    items: [
                        {iconCls: 'refresh', handler: Bicing.refreshPlacemarks}
                    ]
                }
            ],
            items: [Bicing.placemarksList],
            layout: 'fit'
        });

        Bicing.refreshPlacemarks();
    }
});

Ext.setup({
    tabletStartupScreen: '/images/icon.png',
    phoneStartupScreen: '/images/startup-phone.png',
    icon: 'icon.png',
    glossOnIcon: true
});