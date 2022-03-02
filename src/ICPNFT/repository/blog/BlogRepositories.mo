
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";

import BlogDomain "../../domain/blog/BlogDomain";

import TrieRepositories "../TrieRepositories";

module {

    public type AuthorId = BlogDomain.AuthorId;
    public type AuthorProfile = BlogDomain.AuthorProfile;
    public type AuthorPage = TrieRepositories.Page<AuthorProfile>;

    public type UserPrincipal = BlogDomain.UserPrincipal;

    public type AuthorDB = TrieRepositories.TrieDB<AuthorId, AuthorProfile>;
    public type AuthorRepository = TrieRepositories.TrieRepository<AuthorId, AuthorProfile>;
    public type DBKey = TrieRepositories.TrieDBKey<Nat>;

    
    public let authorEq = BlogDomain.authorEq;

    public func dbKey(k: Nat): DBKey {
        { key = k; hash = Hash.hash(k) }
    };

    public func newAuthorDB() : AuthorDB {
        Trie.empty<AuthorId, AuthorProfile>()
    };

    public func newAuthorRepository() : AuthorRepository {
        TrieRepositories.TrieRepository<AuthorId, AuthorProfile>()
    };

    public func saveAuthor(db: AuthorDB, repository: AuthorRepository, profile: AuthorProfile) : AuthorDB {
        let newDB = repository.update(db, profile, dbKey(profile.id), authorEq).0;
        newDB
    };

    public func deleteAuthor(db: AuthorDB, repository: AuthorRepository, authorId: AuthorId) : AuthorDB {
        repository.delete(db, dbKey(authorId), authorEq)
    };

    public func pageAuthor(db: AuthorDB, repository: AuthorRepository, 
        pageSize: Nat, pageNum: Nat, 
        filter: (AuthorId, AuthorProfile) -> Bool, 
        sortWith: (AuthorProfile, AuthorProfile) -> Order.Order) : AuthorPage {
        repository.page(db, pageSize, pageNum, filter, sortWith)
    };

    public func countAuthorTotal(db : AuthorDB) :  Nat {
        Trie.size<AuthorId, AuthorProfile>(db)
    };

};