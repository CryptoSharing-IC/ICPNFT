
module Event {
    public type Callback = shared (msg: Message) -> async ();
    public type TopupCallback = shared () -> async ();

    public type CallbackStatus = {
        callback: ?Callback;
        callsSinceLastTopup: Nat;
        noTopupCallLimit: Nat;
        failedCalls: Nat;
        failedCallsLimit: Nat;
    };

    public type Message = {
        createdAt: Int;
        event: {
            #ContractEvent : Contract;
            #TokenEvent: Token;
        };

        topupCallback: TopupCallback;
        topupAmount: Nat;
    };

    public type Token = {
        #Transfer : {
            id: Text;
            from: Principal;
            to: Principal;
        };
        #Authorize: {
            id: Text;
            user: Principal;
            isAuthorized: Bool;
        };
    };

    public type Contract = {
        #ContractAuthorized : {
            user: Principal;
            isAuthorized: Bool;
        };
        #Mint : {
            id: Text;
            owner: Principal;
        }
    };

    public func createMessage(
        createdAt: Int, 
        event: {
            #ContractEvent : Contract;
            #TokenEvent : Token;
        },
        topupCallback: TopupCallback,
        topupAmount: Nat) : Message {
        {
            createdAt = createdAt;
            event = event;
            topupAmount = topupAmount;
            topupCallback = topupCallback;
        }
    };
}