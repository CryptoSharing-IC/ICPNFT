export const idlFactory = ({ IDL }) => {
  const Property = IDL.Rec();
  const AuthorizeRequest = IDL.Record({
    'p' : IDL.Principal,
    'id' : IDL.Text,
    'isAuthorized' : IDL.Bool,
  });
  const Error = IDL.Variant({
    'Immutable' : IDL.Null,
    'NotFound' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'InvalidRequest' : IDL.Null,
    'AuthorizedPrincipalLimitReached' : IDL.Nat,
    'FailedToWrite' : IDL.Text,
  });
  const Result_1 = IDL.Variant({ 'ok' : IDL.Null, 'err' : Error });
  const ContractInfo = IDL.Record({
    'nft_payload_size' : IDL.Nat,
    'memory_size' : IDL.Nat,
    'max_live_size' : IDL.Nat,
    'cycles' : IDL.Nat,
    'heap_size' : IDL.Nat,
    'authorized_users' : IDL.Vec(IDL.Principal),
    'total_minited' : IDL.Nat,
  });
  const TopupCallback = IDL.Func([], [], []);
  const Contract = IDL.Variant({
    'Mint' : IDL.Record({ 'id' : IDL.Text, 'owner' : IDL.Principal }),
    'ContractAuthorized' : IDL.Record({
      'isAuthorized' : IDL.Bool,
      'user' : IDL.Principal,
    }),
  });
  const Token = IDL.Variant({
    'Authorize' : IDL.Record({
      'id' : IDL.Text,
      'isAuthorized' : IDL.Bool,
      'user' : IDL.Principal,
    }),
    'Transfer' : IDL.Record({
      'id' : IDL.Text,
      'to' : IDL.Principal,
      'from' : IDL.Principal,
    }),
  });
  const Message = IDL.Record({
    'topupCallback' : TopupCallback,
    'createdAt' : IDL.Int,
    'topupAmount' : IDL.Nat,
    'event' : IDL.Variant({ 'ContractEvent' : Contract, 'TokenEvent' : Token }),
  });
  const Callback__1 = IDL.Func([Message], [], []);
  const CallbackStatus = IDL.Record({
    'failedCalls' : IDL.Nat,
    'failedCallsLimit' : IDL.Nat,
    'callback' : IDL.Opt(Callback__1),
    'noTopupCallLimit' : IDL.Nat,
    'callsSinceLastTopup' : IDL.Nat,
  });
  const ContractMetadata = IDL.Record({
    'name' : IDL.Text,
    'symbol' : IDL.Text,
  });
  const Value = IDL.Variant({
    'Int' : IDL.Int,
    'Nat' : IDL.Nat,
    'Empty' : IDL.Null,
    'Bool' : IDL.Bool,
    'Text' : IDL.Text,
    'Float' : IDL.Float64,
    'Principal' : IDL.Principal,
    'Class' : IDL.Vec(Property),
  });
  Property.fill(
    IDL.Record({ 'value' : Value, 'name' : IDL.Text, 'immutable' : IDL.Bool })
  );
  const Properties = IDL.Vec(Property);
  const Egg = IDL.Record({
    'contentType' : IDL.Text,
    'owner' : IDL.Opt(IDL.Principal),
    'properties' : Properties,
    'isPrivate' : IDL.Bool,
    'payload' : IDL.Variant({
      'StagedData' : IDL.Text,
      'Payload' : IDL.Vec(IDL.Nat8),
    }),
  });
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : Error });
  const Result_2 = IDL.Variant({ 'ok' : IDL.Principal, 'err' : Error });
  const UpdateEventCallback = IDL.Variant({
    'Set' : Callback__1,
    'Remove' : IDL.Null,
  });
  const Callback = IDL.Func([], [], []);
  const WriteNFT = IDL.Variant({
    'Init' : IDL.Record({ 'size' : IDL.Nat, 'callback' : IDL.Opt(Callback) }),
    'Chunk' : IDL.Record({
      'id' : IDL.Text,
      'chunk' : IDL.Vec(IDL.Nat8),
      'callback' : IDL.Opt(Callback),
    }),
  });
  const Hub = IDL.Service({
    'authorize' : IDL.Func([AuthorizeRequest], [Result_1], []),
    'balanceOf' : IDL.Func([IDL.Principal], [IDL.Vec(IDL.Text)], ['query']),
    'getContractInfo' : IDL.Func([], [ContractInfo], []),
    'getEventCallbackStatus' : IDL.Func([], [CallbackStatus], []),
    'getMetadata' : IDL.Func([], [ContractMetadata], ['query']),
    'getTotalMinted' : IDL.Func([], [IDL.Nat], ['query']),
    'init' : IDL.Func([IDL.Vec(IDL.Principal), ContractMetadata], [], []),
    'mint' : IDL.Func([Egg], [Result], []),
    'ownerOf' : IDL.Func([IDL.Text], [Result_2], ['query']),
    'transfer' : IDL.Func([IDL.Principal, IDL.Text], [Result_1], []),
    'updateContractOwners' : IDL.Func(
        [IDL.Principal, IDL.Bool],
        [Result_1],
        [],
      ),
    'updateEventCallback' : IDL.Func([UpdateEventCallback], [], []),
    'wallet_receive' : IDL.Func([], [], []),
    'writeStaged' : IDL.Func([WriteNFT], [Result], []),
  });
  return Hub;
};
export const init = ({ IDL }) => { return []; };
