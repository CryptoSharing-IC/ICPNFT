
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import BlogDomain "./domain/blog/BlogDomain";
import BlogRepositories "./repository/blog/BlogRepositories";

actor Blog {

    public type Error = {
        #unauthorized;
    };

    public type AuthorCreateCommand = BlogDomain.AuthorCreateCommand;

    public type DeleteCommand = {
        id: Nat;
    };
    public type PageQuery = {
        pageSize: Nat;
        pageNum: Nat;
    };

    public type Result<X, E> = Result.Result<X, E>;

    public type UserPrincipal = Text;

    /// Author data model 
    public type AuthorPage = BlogRepositories.AuthorPage;
    public type AuthorDB = BlogRepositories.AuthorDB;
    public type AuthorRepository = BlogRepositories.AuthorRepository;

    // Author Storage
    stable var authorDB = BlogRepositories.newAuthorDB();
    let authorRepository = BlogRepositories.newAuthorRepository();

    // 
    /// ID Generator
    stable var idGenerator : Nat = 10001;

    /// Create
    public shared(msg) func createAuthor(cmd: AuthorCreateCommand) : async Result<Nat, Error> {
        let caller = Principal.toText(msg.caller);     
        
        let authorId = getIdAndIncrementOne();
        let currentTime = timeNow_();
        let profile = BlogDomain.authorCreateCommandToProfile(cmd, authorId, caller, currentTime);
        authorDB := BlogRepositories.saveAuthor(authorDB, authorRepository, profile);
        #ok(authorId)          
    };

    /// Delete
    public shared(msg) func deleteAuthor(cmd: DeleteCommand) : async Result<Bool, Error> {
        let caller = Principal.toText(msg.caller);     

        authorDB := BlogRepositories.deleteAuthor(authorDB, authorRepository, cmd.id);
        #ok(true)
  
    };

    /// Query
    public query func pageAuthor(q: PageQuery) : async Result<AuthorPage, Error> {
        #ok(
            BlogRepositories.pageAuthor(authorDB, authorRepository, q.pageSize, q.pageNum, func (id, profile) : Bool {
                true
            }, BlogDomain.authorOrderByIdDesc)
        )
    };

    public query func now() : async Int {
        timeNow_()
    };

    public query func greet(t: Text) : async Text {
        "Hello, " # t
    };

    public query func read() : async Nat {
        idGenerator
    };

    /// ------------------------ private functions -------------------------- ///
    func getIdAndIncrementOne() : Nat {
        let id = idGenerator;
        idGenerator += 1;
        id
    };

    func timeNow_() : Int {
        Time.now()
    };

};
