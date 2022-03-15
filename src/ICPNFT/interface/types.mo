import Time "mo:base/Time";
import TrieSet "mo:base/TrieSet";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Result "mo:base/Result";

module {
    public type NFTMetadata = {
        logo: Text;
        name: Text;
        symbol: Text;
        desc: Text;
        totalSupply: Nat;
    };
    public type Location = {
        #InCanister: Blob; 
        #AssetCanister: (Principal, Blob);
        #IPFS: Text;
        #Web: Text;
    };
    public type Attribute = {
        key: Text;
        value: Text;
    };
    public type TokenMetadata = {
        filetype: Text;
        location: Location;
        attributes: [Attribute];
    };
    public type TokenInfo = {
        index: Nat;
        var owner: Principal;
        var user: Principal; // this token's right to use
        var metadata: ?TokenMetadata;
        var operator: ?Principal;
        var operatorForUse: ?Principal;
        timestamp: Time.Time;
    };

    public type UserInfo = {
        var operators: TrieSet.Set<Principal>;    
        var allowedBy: TrieSet.Set<Principal>;     
        var allowedTokens: TrieSet.Set<Nat>;       

        var allowedTokensUse: TrieSet.Set<Nat>; 
        var tokens: TrieSet.Set<Nat>;     
        var tokenForUse: TrieSet.Set<Nat>;
    };

    public type Errors = {
        #Unauthorized;
        #TokenNotExist;
        #InvalidSpender;
        #InvalidReceiver
    };
    public type CallResult = {
        #Ok: Nat;
        #Err: Errors;
    };
    public type MintResult = {
        #Ok: (Nat, Nat);
        #Err: Errors;
    };
}