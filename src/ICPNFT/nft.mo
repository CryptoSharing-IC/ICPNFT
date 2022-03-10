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