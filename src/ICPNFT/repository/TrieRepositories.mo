
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";


/// 通用的操纵数据集的模块，包括插入/更新，查询，删除，分页等功能
module {
    
    public type Page<T> = {
        data : [T];
        pageSize : Nat;
        pageNum : Nat;
        totalCount: Nat;
    };

    public type TrieDB<K, V> = Trie.Trie<K, V>;
    public type TrieDBKey<K> = Trie.Key<K>;
    

    public class TrieRepository<K, V>() {
        
        public func get(db: TrieDB<K, V>, kk: TrieDBKey<K>, k_eq : (K, K) -> Bool) : ?V {
            Trie.find<K, V>(db, kk, k_eq)        
        };

        public func findBy(db: TrieDB<K, V>, f: (K, V) -> Bool): TrieDB<K, V> {
            let entities = Trie.filter<K, V>(db, f);
            entities
        };

        public func countBy(db: TrieDB<K, V>, f: (K, V) -> Bool) : Nat {       
            Trie.size<K, V>(findBy(db,f))
        };

        public func update(db: TrieDB<K, V>, v: V, kk: TrieDBKey<K>, k_eq : (K, K) -> Bool) : (TrieDB<K, V>, ?V) {
            Trie.put<K, V>(db, kk, k_eq, v);
        };

        public func delete(db: TrieDB<K, V>, kk: TrieDBKey<K>, k_eq : (K, K) -> Bool) : TrieDB<K, V> {
            let res = Trie.remove<K, V>(db, kk, k_eq);
            res.0
        };

        public func page(db: TrieDB<K, V>, pageSize: Nat, pageNum: Nat,
            filter: (K, V) -> Bool, sortWith: (V, V) -> Order.Order) : Page<V> {
            let skipCounter = pageNum * pageSize;
            
            let filtered = Trie.mapFilter<K, V, V>(db, func (k, v) : ?V {
                if (filter(k, v)) {?v} else null
            });
            let dataArray = Trie.toArray<K, V, V>(filtered, func (k, v) : V { v });
            
            let sortedData = List.fromArray<V>(Array.sort(dataArray, sortWith));
            let remainning = List.drop<V>(sortedData, skipCounter);
            let paging = List.take<V>(remainning, pageSize);
            let totalCount = List.size<V>(sortedData);

            {
                data = List.toArray<V>(paging);
                pageSize = pageSize;
                pageNum = pageNum;
                totalCount = totalCount;
            }
        };
    };

    
};