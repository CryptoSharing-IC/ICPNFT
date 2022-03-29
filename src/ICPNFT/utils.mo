
import Buffer "mo:base/Buffer";

module {

    public func arrayAppend<T>(as1: [T], as2: [T]) : [T] {
        let buffer = Buffer.Buffer<T>(as1.size() + as2.size());
        for (t in as1.vals()) {
            buffer.add(t);
        };
        for (t in as2.vals()) {
            buffer.add(t);
        };
        buffer.toArray()
    };
}