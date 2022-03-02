
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Trie "mo:base/Trie";

module {
    
    public type AuthorId = Nat;
    
    public type AuthorProfile = {
        id: AuthorId;   
        avatarId: PictureId;
        name: Text;     
        memo: Text;    
        createdBy: UserPrincipal;      
        createdAt: Timestamp;          
    };

    public type AuthorCreateCommand = {
        avatarId: PictureId; 
        name: Text;     
        memo: Text;     
    };

    public type PictureId = Nat;
    
    public type Timestamp = Int;
    
    public type UserPrincipal = Text;

    // -------------- Domain functions --------------- ///
    public func authorCreateCommandToProfile(cmd: AuthorCreateCommand, authorId: AuthorId, 
        createdBy: UserPrincipal, createdAt: Timestamp) : AuthorProfile {
        {
            id = authorId;
            avatarId = cmd.avatarId;
            name = cmd.name;
            memo = cmd.memo;
            createdBy = createdBy;
            createdAt = createdAt;
        }
    };

    /// 
    public func authorOrderByIdDesc(profile1: AuthorProfile, profile2: AuthorProfile) : Order.Order {
        Nat.compare(profile2.id, profile1.id)
    };

    public let authorEq = Nat.equal;

};