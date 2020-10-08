"use strict";

var vue = new Vue({
    el: '#main-wrapper',
    data: {
        ethAddress: "0x0000000000000000000000000000000000000000",
        transactionHash: null,
        view: "default",
        conversionRates: {
            USD: 0,
            EUR: 0
        },
        lockbox: {
            domain: null,
            id: null,
            price: 0,
            minBidStep: 0,
            blockDuration: 0
        },
        signer: {
            domain: null,
            paymentAddress: null,
            percentage: 0
        },
        error: {
            message: null
        }
    },
    created: function () {
        this.createBlockies();
    },
    updated: function () {
        this.createBlockies();

        //this.$nextTick(function () {
        //    //$("#messages li p").linkify();
        //    //setPanelHeights();
        //    //scrollToBottom();
        //});
    },
    methods: {
        isAddressValid: function (address) {
            return web3.utils.isAddress(address) ? "valid" : "invalid";
        },
        createBlockies: function () {
            var blockiesData = blockies.create({
                seed: this.ethAddress.toLowerCase(),
                size: 8,
                scale: 16
            }).toDataURL();

            $('.blockie').attr('src', blockiesData);
        },
        getFiatAmount: function (eth) {
            return (eth * this.conversionRates.USD).toFixed(4);
        },
        getBlockDurationTime: function (blockDuration) {
            let totalSeconds = (blockDuration * 15);
            let timeSpan = TimeSpan.FromSeconds(totalSeconds);

            return timeSpan.days() + " days, " + timeSpan.hours() + " hours, " + timeSpan.minutes() + " minutes, " + timeSpan.seconds() + " seconds";
        },
        addBlockDays: function () {
            this.lockbox.blockDuration += 5760;

            if (this.lockbox.blockDuration > 80640) {
                this.lockbox.blockDuration = 80640;
            }
        },
        subtractBlockDays: function () {
            this.lockbox.blockDuration -= 5760;

            if (this.lockbox.blockDuration < 0) {
                this.lockbox.blockDuration = 0;
            }
        },
        addBlockHours: function () {
            this.lockbox.blockDuration += 240;

            if (this.lockbox.blockDuration > 80640) {
                this.lockbox.blockDuration = 80640;
            }
        },
        subtractBlockHours: function () {
            this.lockbox.blockDuration -= 240;

            if (this.lockbox.blockDuration < 0) {
                this.lockbox.blockDuration = 0;
            }
        },
        addBlockMinutes: function () {
            this.lockbox.blockDuration += 4;

            if (this.lockbox.blockDuration > 80640) {
                this.lockbox.blockDuration = 80640;
            }
        },
        subtractBlockMinutes: function () {
            this.lockbox.blockDuration -= 4;

            if (this.lockbox.blockDuration < 0) {
                this.lockbox.blockDuration = 0;
            }
        }
    }
});