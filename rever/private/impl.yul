{           
    let i := returndatasize()
    let m := shr(selfbalance(), calldatasize())
    let e := sub(calldatasize(), selfbalance())
    for {} and(
        eq(shr(248, calldataload(i)), shr(248, calldataload(sub(e, i)))),
        lt(i, m)
    ) {i := add(i, selfbalance())} {}
    
    mstore(callvalue(), eq(i, m))
    return(callvalue(), 0x20)
}
