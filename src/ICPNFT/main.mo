
import Array "mo:base/Array";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Event "event";
import Token "token";
import Staged "staged";
import Types "types";
import Utils "utils";

shared ({ caller = hub }) actor class  Hub() = this {
    var MAX_RESULT_SIZE_BYTES = 1_000_000;    // 1 MB default
    var HTTP_STREAMING_SIZE_BYTES = 1_900_000;

    stable var CONTRACT_METADATA : ContractMetadata = {
        name = "none";
        symbol = "none";
    };

    stable var INITALIZED = false;

    stable var TOPUP_AMOUNT = 2_000_000;

    stable var BROKER_CALL_LIMIT = 25;

    stable var BROKER_FAILED_CALL_LIMIT = 25;

    stable var id = 10_000;

    stable var payloadSize = 0;

    stable var nftEntries : [Token.NFTEntry] = [];

    let nfts = Token.NFTs(
        id, 
        payloadSize,
        nftEntries
    );

    // TODO
    // stable var staticAssetsEntries : [(
    //     Text,   // Asset Identifier (path)
    //     Static.Asset    // Asset data.
    // )] = [];
    
    // let staticAssets = StaticAssets(staticAssetsEntries);

    stable var contractOwners : [Principal] = [hub];

    stable var messageBrokerCallback : ?Event.Callback = null;
    stable var messageBrokerCallsSinceLastTopup : Nat = 0;
    stable var messageBrokerFailedCalls : Nat = 0;

    public type UpdateEventCallback = {
        #Set : Event.Callback;
        #Remove;
    };

    // Removes or updates the event Callback.
    public shared ({caller}) func updateEventCallback(update : UpdateEventCallback) : async () {
        assert(_isOwner(caller));
        // TODO : reset  `failed calls/calls since last topup?
        switch (update) { 
            case (#Remove) {
                messageBrokerCallback := null;
            };
            case (#Set(cb)) { 
                messageBrokerCallback := ?cb;
            };
        };

    };

    // Returns the event callback status.
    public shared ({caller}) func getEventCallbackStatus() : async Event.CallbackStatus {
        assert(_isOwner(caller));

        return {
            callback = messageBrokerCallback;
            callsSinceLastTopup = messageBrokerCallsSinceLastTopup;
            failedCalls = messageBrokerFailedCalls;
            noTopupCallLimit = BROKER_CALL_LIMIT;
            failedCallsLimit = BROKER_FAILED_CALL_LIMIT;
        };
    };

    system func preupgrade() {
        id := nfts.currentID();
        payloadSize := nfts.payloadSize();
        nftEntries :=  Iter.toArray(nfts.entries());
        // staticAssetsEntries := Iter.toArray(staticAssets.entries()); // TODO
    };

    system func postupgrade() {
        id := 0;
        payloadSize := 0;
        nftEntries := [];
        // staticAssetsEntries := [];   TODO
    };

    // Initalizes the contract with the given (additional) owner and metadata. Can only be called once.
    // @pre: isOwner
    public shared({caller}) func init(
        owners: [Principal],
        metadata: ContractMetadata,
    ) : async () {
        assert(not INITALIZED and caller == hub);

        contractOwners := Utils.arrayAppend(contractOwners, owners);
        CONTRACT_METADATA := metadata;
        INITALIZED := true;
    };

    // Updates the access rights of one of the contract owners.
    public shared ({caller}) func updateContractOwners(
        user: Principal,
        isAuthorized: Bool,
    ) : async Result.Result<(), Types.Error> {
        if (not _isOwner(caller)) { return #err(#Unauthorized); };

        switch (isAuthorized) { 
            case (true) { 
                contractOwners := Utils.arrayAppend(contractOwners, [user]);
            };
            case (false) { 
                contractOwners := Array.filter<Principal>(contractOwners, func(v) : Bool { v != user })
            };
        };

        ignore _emitEvent(Event.createMessage(
            Time.now(),
            #ContractEvent(
                #ContractAuthorized({
                    user = user;
                    isAuthorized = isAuthorized;
                }),
            ),
            wallet_receive,
            TOPUP_AMOUNT,
        ));

        #ok()
    };

    public shared ({caller}) func wallet_receive() : async () {
        ignore ExperimentalCycles.accept(ExperimentalCycles.available());
    };

    // Returns the meta data of the contract.
    public query func getMetadata() : async ContractMetadata {
        CONTRACT_METADATA
    };

    // Returns the total amount of minted NFTs.
    public query func getTotalMinted() : async Nat {
        nfts.getTotalMinted()
    };

    // Mints a new Egg.
    // @pre : isOwner
    public shared ({caller}) func mint(egg: Token.Egg) : async Result.Result<Text, Types.Error> {
        assert(_isOwner(caller));

        switch (await nfts.mint(Principal.fromActor(this), egg)) {
            case (#err(e)) { #err(#FailedToWrite(e)) };
            case (#ok(id, owner)) { 
                ignore _emitEvent(Event.createMessage(
                    Time.now(),
                    #ContractEvent(
                        #Mint({
                            id = id;
                            owner = owner;
                        })
                    ),
                    wallet_receive,
                    TOPUP_AMOUNT,                
                ));
                #ok(id)
            };
        }
    };

    // Writes a part of an NFT to the staged data.
    // Initalizing another NFT will destruct the data in the buffer.
    public shared ({caller}) func writeStaged(data: Staged.WriteNFT) : async Result.Result<Text, Types.Error> {
        assert(_isOwner(caller));
        switch (await nfts.writeStaged(data)) {
            case (#ok(id)) { #ok(id) };
            case (#err(e)) { #err(#FailedToWrite(e)) };
        }
    };

    // Returns the contract info.
    // @pre : isOwner
    public shared ({caller}) func getContractInfo() : async ContractInfo {
        {
            heap_size = Prim.rts_heap_size();
            memory_size = Prim.rts_memory_size();
            max_live_size = Prim.rts_max_live_size();
            nft_payload_size = payloadSize;
            total_minited = nfts.getTotalMinted();
            cycles = ExperimentalCycles.balance();
            authorized_users = contractOwners;
        }
    };

    // Lists all static assets. TODO
    // @pre : isOwner
    // public query ({caller}) func listAssets() : async [(Text, Text, Nat)] {
    //     assert(_isOwner(caller));
    //     staticAssets.list();
    // };

    // Allows you to replace delete and stage NFTS. TODO
    // Putting and initalizing staged data will overwrite the present data.
    // public shared ({caller}) func assetRequest(data: Static.AssetRequest) : async Result.Result<(), Types.Error> {} {

    // };

    // Returns the token of the given principal
    public query func balanceOf(p: Principal) : async [Text] {
        nfts.tokensOf(p)
    };

    // Returns the owner of the NFT with given identifier.
    public query func ownerOf(id: Text) : async Result.Result<Principal, Types.Error> {
        nfts.ownerOf(id)
    };

    // Transfers one  of your owner NFT to another principal
    public shared ({caller}) func transfer(to: Principal, id: Text) : async Result.Result<(), Types.Error> {
        let owner = switch (_canChange(caller, id)) {
            case (#err(e)) { return #err(e); };
            case (#ok(v)) { v };
        };

        let res = await nfts.transfer(to, id);
        ignore _emitEvent(Event.createMessage(
            Time.now(),
            #TokenEvent(
                #Transfer({
                    from = owner;
                    to = to;
                    id = id;
                })
            ),
            wallet_receive,
            TOPUP_AMOUNT
        ));
        res;
    };

    // Allows the caller to authorize another principal to act on its behalf.
    public shared ({caller}) func authorize(req: Token.AuthorizeRequest) : async Result.Result<(), Types.Error> {
        switch (_canChange(caller, req.id)) {
            case (#err(e)) { return #err(e); };
            case (#ok(_)) {};
        };

        if (not nfts.authorize(req)) {
            return #err(#AuthorizedPrincipalLimitReached(Token.AUTHORIZED_LIMIT));
        };

        ignore _emitEvent(Event.createMessage(
            Time.now(),
            #TokenEvent(
                #Authorize({
                    id = req.id;
                    user = req.p;
                    isAuthorized = req.isAuthorized
                })
            ),
            wallet_receive,
            TOPUP_AMOUNT,
        ));
        #ok()
    };

    public type ContractInfo = {
        heap_size: Nat;
        memory_size: Nat;
        max_live_size: Nat;
        nft_payload_size: Nat;
        total_minited: Nat;
        cycles: Nat;
        authorized_users: [Principal];
    };

    public type ContractMetadata = {
        name: Text;
        symbol: Text;
    };

    /// -------------------- private functions ---------------------- ///
    private func _isOwner(p: Principal) : Bool {
        switch (Array.find<Principal>(contractOwners, func(v) : Bool { return v == p })) {
            case (null) { false };
            case (? v) { true };
        }
    };

    private func _emitEvent(event: Event.Message) : async () {
        let emit = func(broker: Event.Callback, msg: Event.Message) : async () {
            try {
                await broker(msg);
                messageBrokerCallsSinceLastTopup := messageBrokerCallsSinceLastTopup + 1;
                messageBrokerFailedCalls := 0;
            } catch (_) {
                messageBrokerFailedCalls := messageBrokerFailedCalls + 1;
                if (messageBrokerFailedCalls > BROKER_FAILED_CALL_LIMIT) {
                    messageBrokerCallback := null;
                };
            };
        };

        switch (messageBrokerCallback) {
            case (null) { return ; };
            case (? broker) {
                if (messageBrokerCallsSinceLastTopup > BROKER_CALL_LIMIT) return ;
                ignore emit(broker, event);
            }
        }
    };

    private func _canChange(caller: Principal, id: Text) : Result.Result<Principal, Types.Error> {
        let owner = switch (nfts.ownerOf(id)) {
            case (#err(e)) { 
                if (not _isOwner(caller)) return #err(e);

                Principal.fromActor(this)
            };
            case (#ok(v)) {
                // The owner not is the caller
                if (not _isOwner(caller) and v != caller) {
                    // Check whether the caller is authorized
                    if (not nfts.isAuthorized(caller, id)) return #err(#Unauthorized);
                };

                v
            };
        };

        #ok(owner)
    };
}
