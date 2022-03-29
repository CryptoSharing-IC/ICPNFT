import type { Principal } from '@dfinity/principal';
export interface AuthorizeRequest {
  'p' : Principal,
  'id' : string,
  'isAuthorized' : boolean,
}
export type Callback = () => Promise<undefined>;
export interface CallbackStatus {
  'failedCalls' : bigint,
  'failedCallsLimit' : bigint,
  'callback' : [] | [Callback__1],
  'noTopupCallLimit' : bigint,
  'callsSinceLastTopup' : bigint,
}
export type Callback__1 = (arg_0: Message) => Promise<undefined>;
export type Contract = { 'Mint' : { 'id' : string, 'owner' : Principal } } |
  { 'ContractAuthorized' : { 'isAuthorized' : boolean, 'user' : Principal } };
export interface ContractInfo {
  'nft_payload_size' : bigint,
  'memory_size' : bigint,
  'max_live_size' : bigint,
  'cycles' : bigint,
  'heap_size' : bigint,
  'authorized_users' : Array<Principal>,
  'total_minited' : bigint,
}
export interface ContractMetadata { 'name' : string, 'symbol' : string }
export interface Egg {
  'contentType' : string,
  'owner' : [] | [Principal],
  'properties' : Properties,
  'isPrivate' : boolean,
  'payload' : { 'StagedData' : string } |
    { 'Payload' : Array<number> },
}
export type Error = { 'Immutable' : null } |
  { 'NotFound' : null } |
  { 'Unauthorized' : null } |
  { 'InvalidRequest' : null } |
  { 'AuthorizedPrincipalLimitReached' : bigint } |
  { 'FailedToWrite' : string };
export interface Hub {
  'authorize' : (arg_0: AuthorizeRequest) => Promise<Result_1>,
  'balanceOf' : (arg_0: Principal) => Promise<Array<string>>,
  'getContractInfo' : () => Promise<ContractInfo>,
  'getEventCallbackStatus' : () => Promise<CallbackStatus>,
  'getMetadata' : () => Promise<ContractMetadata>,
  'getTotalMinted' : () => Promise<bigint>,
  'init' : (arg_0: Array<Principal>, arg_1: ContractMetadata) => Promise<
      undefined
    >,
  'mint' : (arg_0: Egg) => Promise<Result>,
  'ownerOf' : (arg_0: string) => Promise<Result_2>,
  'transfer' : (arg_0: Principal, arg_1: string) => Promise<Result_1>,
  'updateContractOwners' : (arg_0: Principal, arg_1: boolean) => Promise<
      Result_1
    >,
  'updateEventCallback' : (arg_0: UpdateEventCallback) => Promise<undefined>,
  'wallet_receive' : () => Promise<undefined>,
  'writeStaged' : (arg_0: WriteNFT) => Promise<Result>,
}
export interface Message {
  'topupCallback' : TopupCallback,
  'createdAt' : bigint,
  'topupAmount' : bigint,
  'event' : { 'ContractEvent' : Contract } |
    { 'TokenEvent' : Token },
}
export type Properties = Array<Property>;
export interface Property {
  'value' : Value,
  'name' : string,
  'immutable' : boolean,
}
export type Result = { 'ok' : string } |
  { 'err' : Error };
export type Result_1 = { 'ok' : null } |
  { 'err' : Error };
export type Result_2 = { 'ok' : Principal } |
  { 'err' : Error };
export type Token = {
    'Authorize' : {
      'id' : string,
      'isAuthorized' : boolean,
      'user' : Principal,
    }
  } |
  { 'Transfer' : { 'id' : string, 'to' : Principal, 'from' : Principal } };
export type TopupCallback = () => Promise<undefined>;
export type UpdateEventCallback = { 'Set' : Callback__1 } |
  { 'Remove' : null };
export type Value = { 'Int' : bigint } |
  { 'Nat' : bigint } |
  { 'Empty' : null } |
  { 'Bool' : boolean } |
  { 'Text' : string } |
  { 'Float' : number } |
  { 'Principal' : Principal } |
  { 'Class' : Array<Property> };
export type WriteNFT = {
    'Init' : { 'size' : bigint, 'callback' : [] | [Callback] }
  } |
  {
    'Chunk' : {
      'id' : string,
      'chunk' : Array<number>,
      'callback' : [] | [Callback],
    }
  };
export interface _SERVICE extends Hub {}
