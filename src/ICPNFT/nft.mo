import HashMap "mo:base/HashMap";
import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import TrieSet "mo:base/TrieSet";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Prelude "mo:base/Prelude";
import Buffer "mo:base/Buffer";
import Types "../interface/types";

shared(msg) actor class NFToken(_logo: Text, _name: Text, _symbol: Text, _desc: Text, _ower: Principal) = this {

    type Metadata = Types.Metadata;
    type Location = Types.Location;
    type Attribute = Types.Attribute;
    type TokenMetadata = Types.TokenMetadata;
    type TokenInfo = Types.TokenInfo;
    type UserInfo = Types.UserInfo;
    type Errors = Types.Errors;
    type CallResult = Types.CallResult;
    type MintResult = Types.MintResult;

    private stable var logo : Text = _logo; // base64 encoded image
    private stable var name : Text = _name;
    private stable var symbol : Text = _symbol;
    private stable var desc : Text = _desc;
    private stable var owner : Principal = _owner;
    private stable var totalSupply : Nat = 0;
    private stable var blackhole: Principal = Principal.fromText("aaaaa-aa");

    private stable var tokensEntries : [(Nat, TokenInfo)] = [];
    private stable var usersEntries : [(Principal, UserInfo)] = [];
    private var tokens = HashMap.HashMap<Nat, TokenInfo>(1, Nat.equal, Hash.hash);
    private var users = HashMap.HashMap<Principal, UserInfo>(1, Principal.equal, Principal.hash);

    private func _transfer(to: Principal, tokenId: Nat) {
            assert(_exists(tokenId));
            switch(tokens.get(tokenId)) {
                case (?info) {
                    _removeTokenFrom(info.owner, tokenId);
                    _addTokenTo(to, tokenId);
                    info.owner := to;
                    tokens.put(tokenId, info);
                };
                case (_) {
                    assert(false);
                };
            };
    };


    public shared(msg) func transfer(to: Principal, tokenId: Nat): async TxReceipt {
        var owner: Principal = switch (_ownerOf(tokenId)) {
            case (?own) {
                own;
            };
            case (_) {
                return #err(#TokenNotExist)
            }
        };
        if (owner != msg.caller) {
            return #err(#Unauthorized);
        };
        _transfer(to, tokenId);
        let txid = addTxRecord(msg.caller, #transfer, ?tokenId, #user(msg.caller), #user(to), Time.now());
        return #ok(txid);
    };

    public shared(msg) func transferFrom(from: Principal, to: Principal, tokenId: Nat): async TxReceipt {
        if(_exists(tokenId) == false) {
            return #err(#TokenNotExist)
        };
        if(_isApprovedOrOwner(msg.caller, tokenId) == false) {
            return #err(#Unauthorized);
        };
        _clearApproval(from, tokenId);
        _transfer(to, tokenId);
        let txid = addTxRecord(msg.caller, #transferFrom, ?tokenId, #user(from), #user(to), Time.now());
        return #ok(txid);
    };

    public shared(msg) func batchTransferFrom(from: Principal, to: Principal, tokenIds: [Nat]): async TxReceipt {
        var num: Nat = 0;
        label l for(tokenId in Iter.fromArray(tokenIds)) {
            if(_exists(tokenId) == false) {
                continue l;
            };
            if(_isApprovedOrOwner(msg.caller, tokenId) == false) {
                continue l;
            };
            _clearApproval(from, tokenId);
            _transfer(to, tokenId);
            num += 1;
            ignore addTxRecord(msg.caller, #transferFrom, ?tokenId, #user(from), #user(to), Time.now());
        };
        return #ok(txs.size() - num);
    };
    // public update calls
    public shared(msg) func mint(to: Principal, metadata: ?TokenMetadata): async MintResult {
        if(msg.caller != owner_) {
            return #err(#Unauthorized);
        };
        let token: TokenInfo = {
            index = totalSupply_;
            var owner = to;
            var metadata = metadata;
            var operator = null;
            timestamp = Time.now();
        };
        tokens.put(totalSupply_, token);
        _addTokenTo(to, totalSupply_);
        totalSupply_ += 1;
        let txid = addTxRecord(msg.caller, #mint(metadata), ?token.index, #user(blackhole), #user(to), Time.now());
        return #ok((token.index, txid));
    };

    private func _unwrap<T>(x : ?T) : T =
    switch x {
      case null { Prelude.unreachable() };
      case (?x_) { x_ };
    };
    
    private func _newUser() : UserInfo {
        {
            var operators = TrieSet.empty<Principal>();
            var allowedBy = TrieSet.empty<Principal>();
            var allowedTokens = TrieSet.empty<Nat>();
            var tokens = TrieSet.empty<Nat>();
        }
    };
    private func _exists(tokenId: Nat) : Bool {
        switch (tokens.get(tokenId)) {
            case (?info) { return true; };
            case _ { return false; };
        }
    };

    private func _ownerOf(tokenId: Nat) : ?Principal {
        switch (tokens.get(tokenId)) {
            case (?info) { return ?info.owner; };
            case (_) { return null; };
        }
    };
    
    private func _balanceOf(who: Principal) : Nat {
        switch (users.get(who)) {
            case (?user) { return TrieSet.size(user.tokens); };
            case (_) { return 0; };
        }
    };
    
    private func _isApproved(who: Principal, tokenId: Nat) : Bool {
        switch (tokens.get(tokenId)) {
            case (?info) { return info.operator == ?who; };
            case _ { return false; };
        }
    };
    private func _isApprovedForAll(owner: Principal, operator: Principal) : Bool {
        switch (users.get(owner)) {
            case (?user) {
                return TrieSet.mem(user.operators, operator, Principal.hash(operator), Principal.equal);
            };
            case _ { return false; };
        };
    };
    private func _isApprovedOrOwner(spender: Principal, tokenId: Nat) : Bool {
        switch (_ownerOf(tokenId)) {
            case (?owner) {
                return spender == owner or _isApproved(spender, tokenId) or _isApprovedForAll(owner, spender);
            };
            case _ {
                return false;
            };
        };        
    };

    private func _getApproved(tokenId: Nat) : ?Principal {
        switch (tokens.get(tokenId)) {
            case (?info) {
                return info.operator;
            };
            case (_) {
                return null;
            };
        }
    };
   
    

    public query func getApproved(tokenId: Nat) : async Principal {
        switch (_exists(tokenId)) {
            case true {
                switch (_getApproved(tokenId)) {
                    case (?who) {
                        return who;
                    };
                    case (_) {
                        return Principal.fromText("aaaaa-aa");
                    };
                }   
            };
            case (_) {
                throw Error.reject("token not exist")
            };
        }
    };

    public shared(msg) func approve(tokenId: Nat, operator: Principal) : async CallResult {
        var owner: Principal = switch (_ownerOf(tokenId)) {
            case (?own) {
                own;
            };
            case (_) {
                return #Err(#TokenNotExist)
            }
        };
        if(Principal.equal(msg.caller, owner) == false)
            if(_isApprovedForAll(owner, msg.caller) == false)
                return #Err(#Unauthorized);
        if(owner == operator) {
            return #Err(#InvalidOperator);
        };
        switch (tokens.get(tokenId)) {
            case (?info) {
                info.operator := ?operator;
                tokens.put(tokenId, info);
            };
            case _ {
                return #Err(#TokenNotExist);
            };
        };
        switch (users.get(operator)) {
            case (?user) {
                user.allowedTokens := TrieSet.put(user.allowedTokens, tokenId, Hash.hash(tokenId), Nat.equal);
                users.put(operator, user);
            };
            case _ {
                let user = _newUser();
                user.allowedTokens := TrieSet.put(user.allowedTokens, tokenId, Hash.hash(tokenId), Nat.equal);
                users.put(operator, user);
            };
        };
        return #Ok(txid);
    };
    
    public query func isApprovedForAll(owner: Principal, operator: Principal) : async Bool {
        return _isApprovedForAll(owner, operator);
    };

    public shared(msg) func setApprovalForAll(operator: Principal, value: Bool): async CallResult {
        if(msg.caller == operator) {
            return #Err(#Unauthorized);
        };
        
        if value {
            let caller = switch (users.get(msg.caller)) {
                case (?user) { user };
                case _ { _newUser() };
            };
            caller.operators := TrieSet.put(caller.operators, operator, Principal.hash(operator), Principal.equal);
            users.put(msg.caller, caller);
            let user = switch (users.get(operator)) {
                case (?user) { user };
                case _ { _newUser() };
            };
            user.allowedBy := TrieSet.put(user.allowedBy, msg.caller, Principal.hash(msg.caller), Principal.equal);
            users.put(operator, user);
           
        } else {
            switch (users.get(msg.caller)) {
                case (?user) {
                    user.operators := TrieSet.delete(user.operators, operator, Principal.hash(operator), Principal.equal);    
                    users.put(msg.caller, user);
                };
                case _ { };
            };
            switch (users.get(operator)) {
                case (?user) {
                    user.allowedBy := TrieSet.delete(user.allowedBy, msg.caller, Principal.hash(msg.caller), Principal.equal);    
                    users.put(operator, user);
                };
                case _ { };
            };
            
        };
        return #Ok(200);
    };

    public shared(msg) func setTokenMetadata(tokenId: Nat, new_metadata: TokenMetadata) : async TxReceipt {
        // only canister owner can set
        if(msg.caller != owner_) {
            return #Err(#Unauthorized);
        };
        if(_exists(tokenId) == false) {
            return #Err(#TokenNotExist)
        };
        let token = _unwrap(tokens.get(tokenId));
        let old_metadata = token.metadata;
        token.metadata := ?new_metadata;
        tokens.put(tokenId, token);
        return #Ok(200);
    };
    // upgrade functions
    system func preupgrade() {
        usersEntries := Iter.toArray(users.entries());
        tokensEntries := Iter.toArray(tokens.entries());
    };

    system func postupgrade() {
        type TokenInfo = Types.TokenInfo;
        type UserInfo = Types.UserInfo;

        users := HashMap.fromIter<Principal, UserInfo>(usersEntries.vals(), 1, Principal.equal, Principal.hash);
        tokens := HashMap.fromIter<Nat, TokenInfo>(tokensEntries.vals(), 1, Nat.equal, Hash.hash);
        usersEntries := [];
        tokensEntries := [];
    };


    
}
