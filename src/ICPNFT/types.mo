
import Result "mo:base/Result";

module {
    public type Callback = shared () -> async ();

    public func notify(callback: ?Callback) : async () {
        switch (callback) {
            case (? cb) { ignore cb(); };
            case null return ;
        };
    };

    public type Error = {
        #Unauthorized;
        #NotFound;
        #InvalidRequest;
        #AuthorizedPrincipalLimitReached : Nat;
        #Immutable;
        #FailedToWrite : Text;
    };

    public type TokenId = Text;
};