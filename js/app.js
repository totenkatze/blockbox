"use strict";

const app = {
    ethereum: {
        accounts: [],
        setAccounts: function (accounts) {
            this.accounts = accounts;

            if (this.accounts && this.accounts.length > 0) {
                vue.ethAddress = this.accounts[0];
            }
            else {
                vue.ethAddress = "0x0000000000000000000000000000000000000000";
            }
        },
        lockboxAuction: {
            contract: null,
            chainContractAddresses: {
                3: "0xA3Ff2F7CBEDC5837dB7cEF4112423330b55c472e"
            },
            contractEnabled: async function () {
                if (this.contract && await this.contract.methods.isEnabled().call()) {
                    return true;
                }
                else {
                    vue.error.message = "The contract is currently unavailable. Please refresh this page and try again in a few minutes.";
                    return false;
                }
            },
            checkLockboxOwnerKey: async function (v, r, s, id) {
                if (this.contractEnabled()) {
                    return await this.contract.methods.checkLockboxOwnerKey(v, r, s, id).call();
                }
            },
            checkLockboxBidderKey: async function (v, r, s, id, bidderId) {
                if (this.contractEnabled()) {
                    return await this.contract.methods.checkLockboxBidderKey(v, r, s, id, bidderId).call();
                }
            },
            getLockbox: async function (signerAddress, id) {
                if (this.contractEnabled()) {
                    let lockbox = await this.contract.methods.getLockbox(signerAddress, id).call();

                    lockbox.endBlock = parseFloat(lockbox.endBlock);

                    lockbox.price = parseFloat(web3.utils.fromWei(lockbox.price));
                    lockbox.minBidStep = parseFloat(web3.utils.fromWei(lockbox.minBidStep));

                    return lockbox;
                }
            },
            createLockbox: async function (v, r, s, id, price, minBidStep, blockDuration) {
                if (this.contractEnabled()) {
                    this.contract.methods.createLockbox(v, r, s, id, web3.utils.toWei(price.toString()), web3.utils.toWei(minBidStep.toString()), blockDuration.toString()).send({ from: app.accounts[0] }, function (error, transactionHash) {
                        vue.transactionHash = transactionHash;
                    });
                }
            }
        },
        signerRegistry: {
            contract: null,
            registerSigner: async function (domain, paymentAddress, percentage) {
                if (this.contract) {
                    this.contract.methods.registerSigner(web3.utils.padRight(web3.utils.utf8ToHex(domain), 64), paymentAddress, percentage).send({ from: app.ethereum.accounts[0] }, function (error, transactionHash) {
                        vue.transactionHash = transactionHash;
                    });
                }
            },
            getSigner: async function getSigner(accountAddress) {
                if (this.contract) {
                    let result = await this.contract.methods.getSigner(accountAddress).call().catch((err) => { console.error(err); });

                    result.domain = web3.utils.hexToUtf8(result.domain);
                    result.percentage = parseInt(result.percentage);

                    return result;
                }

                return null;
            },
            getPastSignerRegisteredEvents: async function (pastBlockCount) {
                if (this.contract) {
                    let events = await this.contract.getPastEvents('SignerRegistered', {
                        fromBlock: await web3.eth.getBlockNumber() - pastBlockCount,
                        toBlock: 'latest'
                    });

                    for (let i = 0; i < events.length; i++) {
                        let event = events[i];

                        event.transactionDate = new Date((await web3.eth.getBlock(event.blockNumber)).timestamp * 1000);

                        event.returnValues.domain = web3.utils.hexToUtf8(event.returnValues.domain);
                        event.returnValues.percentage = parseInt(event.returnValues.percentage);
                    }

                    return events;
                }

                return null;
            }
        },
        lockboxRegistry: {
            contract: null,
            getPastLockboxCreatedEvents: async function (pastBlockCount) {
                if (this.contract) {
                    let events = await this.contract.getPastEvents('LockboxCreated', {
                        fromBlock: await web3.eth.getBlockNumber() - pastBlockCount,
                        toBlock: 'latest'
                    });

                    for (let i = 0; i < events.length; i++) {
                        let event = events[i];

                        event.transactionDate = new Date((await web3.eth.getBlock(event.blockNumber)).timestamp * 1000);

                        event.returnValues.id = event.returnValues.id.substring(0, 34);
                        event.returnValues.price = parseFloat(web3.utils.fromWei(event.returnValues.price));
                        event.returnValues.endBlock = parseInt(event.returnValues.endBlock);
                    }

                    return events;
                }

                return null;
            },
            getPastLockboxUpdateddEvents: async function (pastBlockCount) {
                if (this.contract) {
                    let events = await this.contract.getPastEvents('LockboxUpdated', {
                        fromBlock: await web3.eth.getBlockNumber() - pastBlockCount,
                        toBlock: 'latest'
                    });

                    for (let i = 0; i < events.length; i++) {
                        let event = events[i];

                        event.transactionDate = new Date((await web3.eth.getBlock(event.blockNumber)).timestamp * 1000);

                        event.returnValues.id = event.returnValues.id.substring(0, 34);
                        event.returnValues.bid = parseFloat(web3.utils.fromWei(event.returnValues.bid));
                    }

                    return events;
                }

                return null;
            },
            getPastLockboxDeletedEvents: async function (pastBlockCount) {
                if (this.contract) {
                    let events = await this.contract.getPastEvents('LockboxDeleted', {
                        fromBlock: await web3.eth.getBlockNumber() - pastBlockCount,
                        toBlock: 'latest'
                    });

                    for (let i = 0; i < events.length; i++) {
                        let event = events[i];

                        event.transactionDate = new Date((await web3.eth.getBlock(event.blockNumber)).timestamp * 1000);

                        event.returnValues.id = event.returnValues.id.substring(0, 34);
                    }

                    return events;
                }

                return null;
            },

            getPastLockboxSoldEvents: async function (pastBlockCount) {
                if (this.contract) {
                    let events = await this.contract.getPastEvents('LockboxSold', {
                        fromBlock: await web3.eth.getBlockNumber() - pastBlockCount,
                        toBlock: 'latest'
                    });

                    for (let i = 0; i < events.length; i++) {
                        let event = events[i];

                        event.transactionDate = new Date((await web3.eth.getBlock(event.blockNumber)).timestamp * 1000);

                        event.returnValues.id = event.returnValues.id.substring(0, 34);
                        event.returnValues.price = parseFloat(web3.utils.fromWei(event.returnValues.price));
                    }

                    return events;
                }

                return null;
            }
        }
    },
    controllers: {
        lockbox: {
            create: async function () {
                let v = app.utils.getUrlParameter("v", window.location.hash);
                let r = app.utils.getUrlParameter("r", window.location.hash);
                let s = app.utils.getUrlParameter("s", window.location.hash);
                let id = app.utils.getUrlParameter("id", window.location.hash);

                if (v !== "" && r !== "" && s !== "" && id !== "") {
                    let keySigner = await app.ethereum.lockboxAuction.checkLockboxOwnerKey(v, r, s, id);

                    if (keySigner && keySigner.valid) {
                        let signer = await app.ethereum.signerRegistry.getSigner(keySigner.signerAddress);

                        if (signer && signer.enabled) {
                            let domainSigners = await $.getJSON("https://" + signer.domain + "/lockbox/signers");

                            if (domainSigners) {
                                for (let i = 0; i < domainSigners.length; i++) {
                                    if (domainSigners[i] === keySigner.signerAddress) {
                                        vue.view = "lockbox.create";
                                        vue.lockbox.id = id;
                                        vue.lockbox.domain = signer.domain;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            },
            bid: async function () {
                let v = app.utils.getUrlParameter("v", window.location.hash);
                let r = app.utils.getUrlParameter("r", window.location.hash);
                let s = app.utils.getUrlParameter("s", window.location.hash);
                let id = app.utils.getUrlParameter("id", window.location.hash);
                let bidderId = app.utils.getUrlParameter("bidderId", window.location.hash);

                if (v !== "" && r !== "" && s !== "" && id !== "" && bidderId !== "") {
                    let keySigner = await app.ethereum.lockboxAuction.checkLockboxBidderKey(v, r, s, id, bidderId);

                    if (keySigner && keySigner.valid) {
                        let signer = await app.ethereum.signerRegistry.getSigner(keySigner.signerAddress);

                        if (signer && signer.enabled) {
                            let domainSigners = await $.getJSON("https://" + signer.domain + "/lockbox/signers");

                            if (domainSigners) {
                                for (let i = 0; i < domainSigners.length; i++) {
                                    if (domainSigners[i] === keySigner.signerAddress) {
                                        vue.view = "lockbox.create";
                                        vue.lockbox.id = id;
                                        vue.lockbox.domain = signer.domain;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        signer: {
            register: async function () {
                vue.view = "signer.register";
            }
        }
    },
    utils: {
        getUrlParameter: function getUrlParameter(name, source) {
            name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
            let regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
            let results = regex.exec(source);
            return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
        }
    },
    init: async function () {
        let lockboxAuctionContractAddress = this.ethereum.lockboxAuction.chainContractAddresses[await web3.eth.getChainId()];

        if (lockboxAuctionContractAddress) {
            this.ethereum.lockboxAuction.contract = new web3.eth.Contract(await $.getJSON("/abi/lockboxAuctionABI.json"), lockboxAuctionContractAddress);
            this.ethereum.signerRegistry.contract = new web3.eth.Contract(await $.getJSON("/abi/signerRegistryABI.json"), await this.ethereum.lockboxAuction.contract.methods.getSignerRegistrytAddress().call());
            this.ethereum.lockboxRegistry.contract = new web3.eth.Contract(await $.getJSON("/abi/lockboxRegistryABI.json"), await this.ethereum.lockboxAuction.contract.methods.getLockboxRegistrytAddress().call());

            let hashPath = window.location.hash.replace("#!/", "").split("?")[0].split("/");

            if (hashPath.length > 1) {

                let route = {
                    controller: hashPath[0],
                    action: hashPath[1]
                };

                app.controllers[route.controller][route.action]();
            }

            vue.conversionRates = await $.getJSON("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD,EUR");
        }
        else {
            alert("bLOCKBOX is not avaible on the selected chain.");
        }
    }
};