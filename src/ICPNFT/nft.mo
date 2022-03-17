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
    type TxReceipt = Types.TxReceipt;
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

    private func addTxRecord(
        caller: Principal, op: Operation, tokenIndex: ?Nat,
        from: Record, to: Record, timestamp: Time.Time
    ): Nat {
        let record: TxRecord = {
            caller = caller;
            op = op;
            index = txIndex;
            tokenIndex = tokenIndex;
            from = from;
            to = to;
            timestamp = timestamp;
        };
        txs := Array.append(txs, [record]);
        txIndex += 1;
        return txIndex - 1;
    };

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

    private func _transferUser(to: Principal, tokenId: Nat) {
        assert(_exists(tokenId));
        switch(tokens.get(tokenId)) {
            case (?info) {
                info.user := to;
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

    public shared(msg) func transferUser(to: Principal, tokenId: Nat): async TxReceipt {
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
        _transferUser(to, tokenId);
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

    public shared(msg) func transferUserFrom(from: Principal, to: Principal, tokenId: Nat): async TxReceipt {
        if(_exists(tokenId) == false) {
            return #err(#TokenNotExist)
        };
        if(_isApprovedOrOwner(msg.caller, tokenId) == false) {
            return #err(#Unauthorized);
        };
        _transferUser(to, tokenId);
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

    // If the caller is not `from`, it must be approved to move this tokenUser by {approve} or {setApprovalForAll} or {approveUser}.
    public shared(msg) func transferUserFrom(from: Principal, to: Principal, tokenId: Nat) : async TxReceipt {
        var owner: Principal = switch (_ownerOf(tokenId)) {
            case (?own) {
                own;
            };
            case (_) {
                return #Err(#TokenNotExist)
            }
        };
        var user : Principal = switch (_userOf(tokenId)) {
            case (?user) {
                if(user != from)  return #Err(#Unauthorized);
            };
            case (_) {
                return #Err(#Unauthorized);
            }
        }
        if(not _isApprovedOrOwner(msg.caller, tokenId) and not _isApprovedOrUser(msg.caller, tokenId)) {
            return #Err(#Unauthorized);
        }
        //tokenInfo
        switch (tokens.get(tokenId)) {
            case (?info) {
                info.user := to;
                tokens.put(tokenId, info);
            };
            case _ {
                return #Err(#TokenNotExist);
            };
        };

        switch (users.get(from)) {
            case (?from) {
                from.tokenForUse := TrieSet.delete(from.tokenForUse, tokenId, Principal.hash(tokenId), Principal.equal)
            };
            case _ {return #Err(#InvalidSpender);};
        };
        switch (users.get(to)) {
            case (?to) {
                to.tokenForUse := TrieSet.add(to.tokenForUse, tokenId, Principal.hash(tokenId), Principal.equal);
            };
            case _ {return #Err(#InvalidReceiver;};
        };
        
        let txid = addTxRecord(msg.caller, #transferUserFrom, ?tokenId, #user(msg.caller), #user(to), Time.now());
        return #ok(txid);
    };
    public shared(msg) func transferAllFrom(from: Principal, to: Principal, tokenId: Nat) : async TxReceipt {
        transferUserFrom(from, to, tokenId);
        transferFrom(from, to, tokenId);
        let txid = addTxRecord(msg.caller, #transferAllFrom, ?tokenId, #user(msg.caller), #user(to), Time.now());
        return #ok(txid);
    };
    public shared(msg) func batchTransferUserFrom(from: Principal, to: Principal, tokenIds: [Nat]): async TxReceipt {
        var num: Nat = 0;
        label l for(tokenId in Iter.fromArray(tokenIds)) {
            if(_exists(tokenId) == false) {
                continue l;
            };
            if(_isApprovedOrOwner(msg.caller, tokenId) == false) {
                continue l;
            };
            _transferUser(to, tokenId);
            num += 1;
            ignore addTxRecord(msg.caller, #transferFrom, ?tokenId, #user(from), #user(to), Time.now());
        };
        return #ok(txs.size() - num);
    };
    private func _addTokenTo(to: Principal, tokenId: Nat) {
        switch(users.get(to)) {
            case (?user) {
                user.tokens := TrieSet.put(user.tokens, tokenId, Hash.hash(tokenId), Nat.equal);
                users.put(to, user); //todo, is this necessary?
            };
            case _ {
                let user = _newUser();
                user.tokens := TrieSet.put(user.tokens, tokenId, Hash.hash(tokenId), Nat.equal);
                users.put(to, user); 
            };
        }
    };

    private func _removeTokenFrom(owner: Principal, tokenId: Nat) {
        assert(_exists(tokenId) and _isOwner(owner, tokenId));
        switch(users.get(owner)) {
            case (?user) {
                user.tokens := TrieSet.delete(user.tokens, tokenId, Hash.hash(tokenId), Nat.equal);
                users.put(owner, user);
            };
            case _ {
                assert(false);
            };
        }
    };
    // public update calls
    public shared(msg) func mint(to: Principal, metadata: ?TokenMetadata): async MintResult {
        if(msg.caller != owner_) {
            return #err(#Unauthorized);
        };
        let token: TokenInfo = {
            index = totalSupply_;
            var owner = to;
            var user = to;
            var metadata = metadata;
            var operator = null;
            var operatorForUse = null;
            timestamp = Time.now();
        };
        tokens.put(totalSupply_, token);
        _addTokenTo(to, totalSupply_);
        totalSupply_ += 1;
        let txid = addTxRecord(msg.caller, #mint(metadata), ?token.index, #user(blackhole), #user(to), Time.now());
        return #ok((token.index, txid));
    };

    public shared(msg) func _safeMint(to: Principal, metadata: ?TokenMetadata): async MintResult {
        if(msg.caller != owner_) {
            return #err(#Unauthorized);
        };
        let token: TokenInfo = {
            index = totalSupply_;
            var owner = to;
            var user = to;  // who have the use right
            var metadata = metadata;
            var operator = null;
            var operatorForUse = null; // who can operator the use right
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

    private func _userOf(tokenId: Nat) : ?Principal {
        switch (tokens.get(tokenId)) {
            case (?info) { return ?info.user;};
            case (_) {return null;};
        }
    };   
     private func _ownerOf(tokenId: Nat) : ?Principal {
        switch (tokens.get(tokenId)) {
            case (?info) { return ?info.owner; };
            case (_) { return null; };
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
            case (_) {
                return false;
            };
        };        
    };
    private func _isApprovedUserForAll(owner: Principal, operator: Principal) : Bool {
        switch (users.get(owner)) {
            case (?user) {
                return TrieSet.mem(user.allowedTokensUse, operator, Principal.hash(operator), Principal.equal);
            };
            case _ { return false; };
        };
    };  
   private func _isApprovedOrUser(spender: Principal, tokenId) {
     
        switch (_userOf(tokenId)) {
            case (?user) {
                return spender == user or _getApprovedUser(tokenId) == spender or _isApprovedUserForAll(owner, spender);
            };
            case (_) {
                return false;
            }
        }
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
   
   private func _getApprovedUser(tokenId: Nat) {
       switch (tokens.get(tokenId)) {
           case (?info) {
               return info.operatorForUse;
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

    public shared(msg) func approve(tokenId: Nat, operator: Principal) : async TxReceipt {
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
        let txid = addTxRecord(msg.caller, #approve, ?tokenId, #user(msg.caller), #user(operator), Time.now());
        return #Ok(txid);
    };

    public shared(msg) func approveUser(operator: Principal, tokenId: Nat)) : async TxReceipt {
        var owner: Principal = switch (_ownerOf(tokenId)) {
            case (?own) {
                own;
            };
            case (_) {
                return #Err(#TokenNotExist)
            }
        };
        var user: Principal = _userOf(tokenId);
        if(user == operator) {
            return #Err(#Unauthorized);
        } 

        if(not _isApprovedOrOwner(msg.caller, tokenId) and not _isApprovedOrUser(msg.call, tokenId)) {
            return #Err(#Unauthorized);
        }
        switch (tokens.get(tokenId)) {
            case (?info) {
                info.operatorForUse := ?operator;
                tokens.put(tokenId, info);
            };
            case _ {
                return #Err(#TokenNotExist);
            };
        }; 
        switch (users.get(operator)) {
            case (?user) {
                user.allowedTokensUse := TrieSet.put(user.allowedTokensUse, tokenId, Hash.hash(tokenId), Nat.equal);
                users.put(operator, user);
            };
            case _ {
                let user = _newUser();
                user.allowedTokensUse := TrieSet.put(user.allowedTokensUse, tokenId, Hash.hash(tokenId), Nat.equal);
                users.put(operator, user);
            };
        };
        let txid = addTxRecord(msg.caller, #approveUser, ?tokenId, #user(msg.caller), #user(operator), Time.now());
        return #Ok(txid);
    } 
    
    
    public query func isApprovedForAll(owner: Principal, operator: Principal) : async Bool {
        return _isApprovedForAll(owner, operator);
    };

    public shared(msg) func setApprovalForAll(operator: Principal, value: Bool): async TxReceipt {
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
            txid := addTxRecord(msg.caller, #revokeAll, null, #user(msg.caller), #user(operator), Time.now());
        };
        return #Ok(txid);
    };

    public shared(msg) func setTokenMetadata(tokenId: Nat, new_metadata: TokenMetadata) : async TxReceipt {

        var owner: Principal = switch (_ownerOf(tokenId)) {
            case (?own) {
                own;
            };
            case (_) {
                return #Err(#TokenNotExist)
            }
        };
        // only canister owner can set
        if(msg.caller != owner) {
            return #Err(#Unauthorized);
        };
        if(_exists(tokenId) == false) {
            return #Err(#TokenNotExist)
        };
        let token = _unwrap(tokens.get(tokenId));
        let old_metadata = token.metadata;
        token.metadata := ?new_metadata;
        tokens.put(tokenId, token);
        let txid = addTxRecord(msg.caller, #setMetadata, ?token.index, #metadata(old_metadate), #metadata(?new_metadata), Time.now());
        return #Ok(txid);
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