
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import MapHelper "mapHelper";
import Property "property";
import Staged "staged";
import Types "types";
import Utils "utils";

module Token {

    public let AUTHORIZED_LIMIT = 25;

    public type TokenId = Types.TokenId;

    public type AuthorizeRequest = {
        id: TokenId;
        p: Principal;
        isAuthorized: Bool;
    };

    public type Token = {
        parents: [TokenId];     // 源 NFT, 可能是 0, 1, 或 多个
        payload: [Blob];
        contentType: Text;
        createdAt: Int;
        properties: Property.Properties;    // 任意多个 Key-Value 属性列表
        isDerivative: Bool;     // 是否衍生 NFT
        startTime:  ?Int;       // 有效期起始时间
        endTime:    ?Int;       // 有效期结束时间
        isPrivate: Bool;    
    };

    public func newToken(
        parents: [TokenId],
        payload: [Blob],
        contentType: Text,
        createdAt: Int,
        properties: Property.Properties,
        isDerivative: Bool,
        startTime: ?Int,
        endTime: ?Int,
        isPrivate: Bool
    ) : Token {
        {
            parents = parents;
            payload = payload;
            contentType = contentType;
            createdAt = createdAt;
            properties = properties;
            isDerivative = isDerivative;
            startTime = startTime;
            endTime = endTime;
            isPrivate = isPrivate;
        }
    };

    public type Metadata = {
        id: TokenId;
        contentType: Text;
        owner: Principal;
        createdAt: Int;
        properties: Property.Properties;
    };

    public type PublicToken = {
        id: TokenId;
        payload: PayloadResult;
        contentType: Text;
        owner: Principal;
        createdAt: Int;
        properties: Property.Properties;
    };

    public type PayloadResult = {
        #Complete : Blob;
        #Chunk : Chunk;
    };

    public type Chunk = {
        data: Blob;
        nextPage: ?Nat;
        totalPages: Nat;
    };

    public type Egg = {
        payload : {
            #Payload : Blob;
            #StagedData : Text;
        };
        contentType : Text;
        owner: ?Principal;
        properties: Property.Properties;
        isPrivate: Bool;
    };

    public type NFTEntry = (
        TokenId,   // Token Identifier
        (
            ?Principal, // Owner of the token
            [Principal],    // Authorized principal
        ),
        Token.Token, // NFT data
    );

    public class NFTs(
        lastID: Nat,
        lastTotalSize: Nat,
        nftEntries: [NFTEntry]
    ) {
        var id = lastID;
        public func currentID() : Nat { id };

        var totalSize = lastTotalSize;
        public func payloadSize() : Nat { id };

        var stagedData = Staged.empty<Text>(
            0, Text.equal, Text.hash
        );

        let nfts = HashMap.HashMap<Text, Token>(nftEntries.size(), Text.equal, Text.hash);
        let authorized = HashMap.HashMap<Text, [Principal]>(0, Text.equal, Text.hash);

        let nftToOwner = HashMap.HashMap<Text, Principal>(nftEntries.size(), Text.equal, Text.hash);
        let ownerToNFT = HashMap.HashMap<Principal, [Text]>(nftEntries.size(), Principal.equal, Principal.hash);

        for ((t, (p, ps), nft) in nftEntries.vals()) {
            nfts.put(t, nft);
            if (ps.size() != 0) {
                authorized.put(t, ps);
            };
            switch (p) {
                case (null) {};
                case (? v) {
                    nftToOwner.put(t, v);
                    switch (ownerToNFT.get(v)) {
                        case (null) { ownerToNFT.put(v, [t]); };
                        case (? ts) { ownerToNFT.put(v, Utils.arrayAppend(ts, [t])); };
                    };
                };
            };
        };

        public func entries() : Iter.Iter<NFTEntry> {
            return Iter.map<(Text, Token), NFTEntry>(
                nfts.entries(),
                func ((t, n) : (Text, Token)) : NFTEntry {
                    let ps = switch (authorized.get(t)) {
                        case (null) { [] };
                        case (? v) { v };
                    };
                    switch (nftToOwner.get(t)) {
                        case (null) { (t, (null, ps), n) };
                        case (? p) { (t, (?p, ps), n) };
                    }
                },
            );
        };

        public func getTotalMinted() : Nat { 
            return nfts.size();
        };

        public func mint(hub: Principal, egg: Egg) : async Result.Result<(Text, Principal), Text> {
            let (size, id_) : (Nat, Text) = switch (egg.payload) {  
                case (#Payload(v)) {
                    let id_ = Nat.toText(id);
                    id += 1;
                    nfts.put(id_ , newToken(
                        [], [v], egg.contentType, Time.now(), egg.properties, false, null, null, egg.isPrivate)
                    );
                
                    (v.size(), id_)
                };
                case (#StagedData(id_)) { 
                    switch (stagedData.get(id_)) {
                        case (null) { 
                            return #err("data was not initalized or was removed (pass ttl)");
                        };
                        case (? (ttl, data)) {
                            if (ttl < Time.now()) {
                                stagedData.delete(id_);
                                return #err("data was removed (pass ttl)");
                            };

                            nfts.put(id_ , newToken(
                                [], data.toArray(), egg.contentType, Time.now(), egg.properties, false, null, null, egg.isPrivate)
                            );
            
                            var size = 0;
                            for (x in data.vals()) {
                                size := size + x.size();
                            };
                            stagedData.put(id_ , (
                                Time.now() + Staged.TTL,
                                Buffer.Buffer(0),
                            ));

                            (size, id_)
                        };
                    };
                };
            };

            totalSize += size;

            let owner = switch (egg.owner) {
                case (null) hub;
                case (? v) v;
            };

            nftToOwner.put(id_ , owner);
            MapHelper.add<Principal, Text>(
                ownerToNFT,
                owner, 
                id_,
                MapHelper.textEqual(id_),
            );

            #ok(id_ , owner)
        };

        public func writeStaged(data: Staged.WriteNFT) : async Result.Result<Text, Text> {
            switch (data) {
                case (#Init(v)) {
                    let id_ = Nat.toText(id);
                    stagedData.put(
                        id_ ,
                        (Time.now() + Staged.TTL, Buffer.Buffer(v.size))
                    );
                    id += 1;
                    ignore Types.notify(v.callback);
                    #ok(id_)
                };
                case (#Chunk(v)) {
                    switch (stagedData.get(v.id)) {
                        case (null) {
                            return #err("data was not initalized or was removed (pass ttl)");
                        };
                        case (? (ttl, buffer)) {
                            if (ttl < Time.now()) {
                                stagedData.delete(v.id);
                                return #err("data was removed (pass ttl)");
                            };
                            let buf = buffer;
                            buf.add(v.chunk);
                            stagedData.put(
                                v.id,
                                (Time.now() + Staged.TTL, buf)
                            );
                            ignore Types.notify(v.callback);
                            #ok(v.id)
                        };
                    };
                };
            }
        };

        public func tokensOf(p: Principal) : [Text] {
            switch (ownerToNFT.get(p)) {
                case (null) { [] };
                case (? v) { v };
            }
        };

        public func ownerOf(id: Text) : Result.Result<Principal, Types.Error> {
            switch (nftToOwner.get(id)) {
                case (null) { #err(#NotFound) };
                case (? p) { #ok(p) };
            }
        };

        public func transfer(to: Principal, id: Text) : async Result.Result<(), Types.Error> {
            switch (nfts.get(id)) {
                case (null) { return #err(#NotFound) };
                case (?v) {};
            };

            switch (nftToOwner.get(id)) {
                case (null) {};
                case (? v) {
                    // Can't send NFT to yourself.
                    if (v == to) { return #err(#InvalidRequest); };

                    // Remove the previous owner.
                    MapHelper.filter<Principal, Text>(
                        ownerToNFT,
                        v,
                        id,
                        MapHelper.textNotEqual(id)
                    );
                };
            };

            nftToOwner.put(id, to);
            authorized.delete(id);
            MapHelper.add<Principal, Text>(
                ownerToNFT,
                to,
                id,
                MapHelper.textEqual(id),
            );
            #ok()
        };

        public func isAuthorized(p: Principal, id: Text) : Bool { 
            switch (authorized.get(id)) {
                case (null) false;
                case (? ps) {
                    switch (Array.find<Principal>(ps, func(v) : Bool { p == v })) {
                        case (null) false;
                        case (? v) true;
                    }
                };
            };
        };

        public func authorize(req: AuthorizeRequest) : Bool {
            if (not req.isAuthorized) {
                MapHelper.filter<Text, Principal>(
                    authorized,
                    req.id,
                    req.p,
                    func (v) : Bool { v != req.p },
                );

                return true;
            };

            MapHelper.addIfNotLimit<Text, Principal>(
                authorized,
                req.id,
                req.p,
                AUTHORIZED_LIMIT,
                MapHelper.principalEqual(req.p),
            )

        };

    };
};