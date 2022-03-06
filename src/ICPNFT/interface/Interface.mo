import Principal "mo:base/Principal";
import Nat "mo:base/Nat";

module{
    public type IERCX = actor {
        Transfer:shared(from:Principal, to:Principal, tokenId:Nat) -> async ();
        Approval:shared(owner:Principal, approved:Principal, tokenId:Nat)-> async ();
        safeTransferFrom:shared(from:Principal, to:Principal, tokenId:Nat)-> async ();
        transferFrom:shared(from:Principal, to:Principal, tokenId:Nat)  -> async ();
        balanceOf:shared(owner:Principal) -> async ();
        safeTransferFromData:shared(from:Principal,to:Principal,tokenId:Nat, data:Nat)-> async ();
        approve:shared(to:Principal, tokenId:Nat)-> async ();
        getApproved:shared(tokenId:Nat)-> async ?Principal; 
    };
};
