
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";

import Utils "utils";

// MapHelper contains helper function to interact with hash maps
module {
    
    // Returns a function that checks whether the given value is equal to a previously defined value `v`.
    // e.g. textEqual("foo")
    //      = func (v: Text): Bool { v == "foo" }
    public func textEqual(w: Text) : (v: Text) -> Bool = func(v: Text) : Bool { w == v };
    public func textNotEqual(w: Text) : (v: Text) -> Bool = func(v: Text) : Bool { w != v };

    public func principalEqual (w : Principal) : (v : Principal) -> Bool = func(v : Principal) { v == w; };

    // Adds the given value to the value array of the hashmap if it does not already exists.
    public func add<K, V>(
        // Hash map to add to.
        map: HashMap.HashMap<K, [V]>,
        // Key of the array to add to.
        k: K,
        // Value to add to the target array.
        v: V,
        // Search function to check whether the value matches an element of the array.
        f: V -> Bool
    ) {
        ignore _addIfNotLimit(map, k, v, null, f)
    };

    // Adds the given value to the value array of the hash map if it does not already exists.
    // Returns `true` if the value was added and thus whether the array did not exceed its limit.
    public func addIfNotLimit<K, V>(
        // hash map to add to.
        map: HashMap.HashMap<K, [V]>,
        k: K,
        v: V,
        // limit on the number of elements in the array.
        limit: Nat, 
        f: V -> Bool,
    ) : Bool {
        _addIfNotLimit(map, k, v, ?limit, f)
    };

    private func _addIfNotLimit<K, V>(
        map: HashMap.HashMap<K, [V]>,
        k: K,
        v: V,
        limit: ?Nat,
        f: V -> Bool
    ) : Bool { 
        switch (map.get(k)) {
            case (null) { map.put(k, [v]); };
            // Key already exists
            case (? vs) { 
                // Check whether the array reached/exceeded the limit.
                switch (limit) { 
                    case (null) {};
                    case (? l) {
                        if (vs.size() >= l) {
                            return false;
                        };
                    };
                };

                switch (Array.find<V>(vs, f)) {
                    case (null) { 
                        map.put(k, Utils.arrayAppend(vs, [v]));
                    };
                    case (? _) {};
                };
            };
        };

        true
    };

    // Filters out all elements based on the given search func `f`.
    // If no elements match, the entry is removed from the hash map
    public func filter<K, V>(
        map: HashMap.HashMap<K, [V]>,
        k: K,
        v: V,
        f: V -> Bool
    ) {
        switch (map.get(k)) {
            case (null) {};
            case (? vs) {
                let new = Array.filter(vs, f);
                if (new.size() > 0) {
                    map.put(k, new);
                } else {
                    map.delete(k);
                }
            }
        }
    };

};